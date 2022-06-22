import json
import os

from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.data_classes import event_source, SNSEvent

from model import AutoscalingLifecylceMessage
from model import get_required_environment_variable, Ec2Helper, AutoscalingHelper

# api = APIGatewayRestResolver()

logger = Logger(service="APP")
tracer = Tracer(service="APP")
metrics = Metrics(namespace="MyApp", service="APP")

# Boto3 Clients
region = os.environ['AWS_REGION']
ec2_helper = Ec2Helper(logger, region_name=region)
autoscaling_helper = AutoscalingHelper(logger, region_name=region)


# @event_source(data_class=SNSEvent)
# def lambda_handler(event: SNSEvent, context):
#     # Multiple records can be delivered in a single event
#     for record in event.records:
#         message = record.sns.message
#         subject = record.sns.subject
#
#         do_something_with(subject, message)

@tracer.capture_lambda_handler
@logger.inject_lambda_context(
    correlation_id_path=correlation_paths.EVENT_BRIDGE, log_event=True
)
@metrics.log_metrics(capture_cold_start_metric=True)
@event_source(data_class=SNSEvent)
def lambda_handler(event: SNSEvent, context):
    vpc_id = get_required_environment_variable("VPC_ID")
    cidr_block_to_route = get_required_environment_variable("CIDR_BLOCK_TO_ROUTE")

    sns_event = {}
    try:
        for record in event.records:
            sns_event = record.sns
            logger.info(f"{sns_event.subject}")
            message: dict = json.loads(record.sns.message)

            logger.info(f"{message}")

            alm = AutoscalingLifecylceMessage.from_dict(message, logger)

            if alm is not None:
                # The Route Tables associated with the instance via the VPC
                route_tables = ec2_helper.get_route_tables_in_vpc(vpc_id)

                # Always check for and remove blackhole routes.
                ec2_helper.remove_blackhole_routes(route_tables)

                if alm.is_ec2_instance_launching():
                    network_interface = ec2_helper.get_first_network_interface(alm.ec2_instance_id)
                    network_interface_id = network_interface['NetworkInterfaceId']
                    logger.info(f"New Instance: adding routes for instance ({alm.ec2_instance_id}) "
                                f"to ({cidr_block_to_route}) network interface ({network_interface_id})")
                    ec2_helper.add_routes_for_interface_id(
                        route_tables,
                        network_interface_id,
                        cidr_block_to_route
                    )
                    logger.info(f"Disabling Source/Dest check for instance ({alm.ec2_instance_id})")
                    ec2_helper.no_source_dest_check(alm.ec2_instance_id)

                elif alm.is_ec2_instance_terminating():
                    network_interfaces = ec2_helper.get_network_interfaces(alm.ec2_instance_id)
                    for ni in network_interfaces:
                        nid = ni['NetworkInterfaceId']
                        logger.info(f"Terminating Instance [{alm.ec2_instance_id}]: remove routes for "
                                    f"interface {nid} to {cidr_block_to_route}")
                        ec2_helper.remove_routes_for_interface_id(route_tables, nid)

        # Complete the autoscaling lifecycle
        logger.info(f"Autoscaling Lifecycle Complete for autoscaling "
                    f"event {alm.lifecycle_hook_name}.")
        autoscaling_helper.complete_lifecycle_action(event=alm)

    except Exception as e:
        logger.error(e)
        raise

    logger.info(f"Exiting....")
    return json.loads(json.dumps(sns_event, default=str))
