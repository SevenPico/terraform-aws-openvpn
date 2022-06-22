import os
import json
import boto3
from botocore.exceptions import ClientError
import time

# boto3.set_stream_logger('')


class MissingEnvironmentVariable(Exception):
    pass


def get_required_environment_variable(variable_name):
    try:
        result = os.environ[variable_name]
        return result
    except KeyError:
        raise MissingEnvironmentVariable(f"Environment Variable [{variable_name}] does not exist.")


class Ec2Helper:
    def __init__(self, logger, region_name="us-east-1"):
        self.client = boto3.client("ec2", region_name=region_name)
        self.resource = boto3.resource('ec2', region_name=region_name)
        self.logger = logger

    def get_route_tables_in_vpc(self, vpc_id):
        return self.client.describe_route_tables(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]},
                # {'Name': f'tag:{tag}','Values': tag_values}
            ]
        )['RouteTables']

    def remove_blackhole_routes(self, route_tables):
        self.logger.info(f"Reviewing routes for removal.")
        for route_table in route_tables:
            for route in route_table['Routes']:
                try:
                    self.logger.info(f"Reviewing route for blackhole: {route}")

                    if route['State'] == "blackhole":
                        self.logger.info(f"Deleting blackhole route to {route['DestinationCidrBlock']} "
                                         f"in Route Table ID {route_table['RouteTableId']}")
                        self.client.delete_route(
                            DestinationCidrBlock=route['DestinationCidrBlock'],
                            RouteTableId=route_table['RouteTableId']
                        )
                except ClientError:
                    self.logger.error(f"Unable to update Route in Route Table:  {route}")

    def remove_routes_for_interface_id(self, route_tables, network_interface_id):
        self.logger.info(f"Reviewing routes to remove for network_interface [{network_interface_id}].")
        for route_table in route_tables:
            for route in route_table['Routes']:
                try:
                    self.logger.info(f"Reviewing route: {route}")
                    if "NetworkInterfaceId" in route.keys() and route['NetworkInterfaceId'] == network_interface_id:
                        self.logger.info(f"Deleting route for {network_interface_id} to {route['DestinationCidrBlock']} "
                                         f"in Route Table ID {route_table['RouteTableId']}")
                        self.client.delete_route(
                            DestinationCidrBlock=route['DestinationCidrBlock'],
                            RouteTableId=route_table['RouteTableId']
                        )

                except ClientError:
                    self.logger.error(f"Unable to update Route in Route Table:  {route}")

    def add_routes_for_interface_id(self, route_tables, network_interface_id, cidr_block):
        self.logger.info(f"Reviewing routes to add for for {network_interface_id} with {cidr_block}.")
        for route_table in route_tables:
            route_table_id = route_table['RouteTableId']
            self.logger.info(f"Adding routes for {network_interface_id} with {cidr_block} in route table ({route_table_id}).")
            try:
                self.client.create_route(
                    DryRun=False,
                    RouteTableId=route_table_id,
                    DestinationCidrBlock=cidr_block,
                    NetworkInterfaceId=network_interface_id
                )
            except ClientError as client_error:
                self.logger.warn(f"Unable to add Route in Route Table ({route_table_id}).")
                self.logger.warn(f"{client_error}.")

    def no_source_dest_check(self, instance_id):
        return self.client.modify_instance_attribute(InstanceId=instance_id, SourceDestCheck={'Value': False})

    def get_instance(self, instance_id):
        return self.resource.Instance(instance_id)

    def get_first_network_interface(self, instance_id):
        """Returns the first network interface of the EC2 Instance."""
        self.logger.info(f"Getting network interface for instance {instance_id}")

        # Get interfaces for this instance with device index 0
        interfaces_dict = {}
        result = {}
        count = 0
        while count < 60:
            try:
                interfaces_dict = self.client.describe_network_interfaces(
                    Filters=[
                        {
                            "Name": "attachment.instance-id",
                            "Values": [instance_id]
                        },
                        {
                            "Name": "attachment.device-index",
                            "Values": ["0"]
                        }]
                )
                self.logger.debug(f"Found interface dict: {interfaces_dict}")
                result = interfaces_dict['NetworkInterfaces'][0]
            except:
                self.logger.warning("Is interface 0 ready?  Trying again......")
                time.sleep(1)
                count += 1
                continue

            self.logger.info(f"Interface 0 ready and set to go: {result}")
            break

        return result

    def get_network_interfaces(self, instance_id):
        """Returns the network interface IDs of the EC2 Instance."""
        self.logger.info(f"Getting the network interface IDs for instance {instance_id}")

        # Get interfaces for this instance with device index 0
        interfaces_dict = {}
        result = {}

        try:
            interfaces_dict = self.client.describe_network_interfaces(
                Filters=[
                    {
                        "Name": "attachment.instance-id",
                        "Values": [instance_id]
                    }]
            )
            self.logger.debug(f"Found interface dict: {interfaces_dict}")
            result = interfaces_dict['NetworkInterfaces']
        except:
            self.logger.warning("Unable to get the network interfaces for instance.")

        return result


class AutoscalingLifecylceMessage(object):
    def __init__(self, message: dict):
        self.origin = message.get("Origin")
        self.lifecycle_hook_name = message.get("LifecycleHookName")
        self.destination = message.get("Destination")
        self.account_id = message.get("AccountId")
        self.request_id = message.get("RequestId")
        self.lifecycle_transition = message.get("LifecycleTransition")
        self.auto_scaling_group_name = message.get("AutoScalingGroupName")
        self.service = message.get("Service")
        self.time = message.get("Time")
        self.ec2_instance_id = message.get("EC2InstanceId")
        self.lifecycle_action_token = message.get("LifecycleActionToken")

    def is_ec2_instance_terminating(self):
        return "autoscaling:EC2_INSTANCE_TERMINATING" in self.lifecycle_transition

    def is_ec2_instance_launching(self):
        return "autoscaling:EC2_INSTANCE_LAUNCHING" in self.lifecycle_transition

    @classmethod
    def from_dict(cls, message: dict, logger):
        logger.debug(f"Processing message: {message}")
        if "Event" in message:
            if message.get("Event") == "autoscaling:TEST_NOTIFICATION":
                logger.info("GOT TEST NOTIFICATION. Do nothing")
                return
            elif message.get("Event") == "autoscaling:EC2_INSTANCE_LAUNCH":
                logger.info("GOT launch notification...will get launching event from lifecyclehook")
                return
            elif message.get("Event") == "autoscaling:EC2_INSTANCE_TERMINATE":
                logger.info("GOT terminate notification....will get terminating event from lifecyclehook")
                return
            elif message.get("Event") == "autoscaling:EC2_INSTANCE_TERMINATE_ERROR":
                logger.info("GOT a GW terminate error...raise exception for now")
                raise Exception("Failed to terminate a GW in an autoscale event")
            elif message.get("Event") == "autoscaling:EC2_INSTANCE_LAUNCH_ERROR":
                logger.info("GOT a GW launch error...raise exception for now")
                raise Exception("Failed to launch a GW in an autoscale event")
        elif "LifecycleTransition" in message:
            if message.get("LifecycleTransition") == "autoscaling:EC2_INSTANCE_LAUNCHING":
                logger.info("Lifecyclehook Launching")
                return AutoscalingLifecylceMessage(message)
            elif message.get("LifecycleTransition") == "autoscaling:EC2_INSTANCE_TERMINATING":
                logger.info("Lifecyclehook Terminating")
                return AutoscalingLifecylceMessage(message)
            else:
                logger.warn(f"Unhandled lifeycycle transition messages received: {message}")
                return


class AutoscalingHelper:
    def __init__(self, logger, region_name="us-east-1"):
        self.client = boto3.client("autoscaling", region_name=region_name)
        self.logger = logger

    def complete_lifecycle_action(self, event: AutoscalingLifecylceMessage, event_completed: bool = True):
        if event_completed:
            action_result = "CONTINUE"
        else:
            action_result = "ABANDON"

        self.logger.info(f"Completing lifecycle action for {event.lifecycle_hook_name} with action_result {action_result}.")
        self.client.complete_lifecycle_action(LifecycleHookName=event.lifecycle_hook_name,
                                              AutoScalingGroupName=event.auto_scaling_group_name,
                                              LifecycleActionToken=event.lifecycle_action_token,
                                              LifecycleActionResult=action_result)
                                              # InstanceId=event.ec2_instance_id)
