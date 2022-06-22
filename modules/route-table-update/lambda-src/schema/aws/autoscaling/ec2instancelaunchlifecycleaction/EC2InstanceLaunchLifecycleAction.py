# coding: utf-8
import pprint
import re  # noqa: F401

import six
from enum import Enum


class EC2InstanceLaunchLifecycleAction(object):
    _types = {
        'LifecycleHookName': 'str',
        'LifecycleTransition': 'str',
        'AutoScalingGroupName': 'str',
        'EC2InstanceId': 'str',
        'LifecycleActionToken': 'str',
        'NotificationMetadata': 'str',
        'Origin': 'str',
        'Destination': 'str'
    }

    _attribute_map = {
        'LifecycleHookName': 'LifecycleHookName',
        'LifecycleTransition': 'LifecycleTransition',
        'AutoScalingGroupName': 'AutoScalingGroupName',
        'EC2InstanceId': 'EC2InstanceId',
        'LifecycleActionToken': 'LifecycleActionToken',
        'NotificationMetadata': 'NotificationMetadata',
        'Origin': 'Origin',
        'Destination': 'Destination'
    }

    def __init__(self, LifecycleHookName=None, LifecycleTransition=None, AutoScalingGroupName=None, EC2InstanceId=None,
                 LifecycleActionToken=None, NotificationMetadata=None, Origin=None, Destination=None):  # noqa: E501
        self._LifecycleHookName = None
        self._LifecycleTransition = None
        self._AutoScalingGroupName = None
        self._EC2InstanceId = None
        self._LifecycleActionToken = None
        self._NotificationMetadata = None
        self._Origin = None
        self._Destination = None
        self.discriminator = None
        self.LifecycleHookName = LifecycleHookName
        self.LifecycleTransition = LifecycleTransition
        self.AutoScalingGroupName = AutoScalingGroupName
        self.EC2InstanceId = EC2InstanceId
        self.LifecycleActionToken = LifecycleActionToken
        self.NotificationMetadata = NotificationMetadata
        self.Origin = Origin
        self.Destination = Destination

    @property
    def LifecycleHookName(self):

        return self._LifecycleHookName

    @LifecycleHookName.setter
    def LifecycleHookName(self, LifecycleHookName):

        self._LifecycleHookName = LifecycleHookName

    @property
    def LifecycleTransition(self):

        return self._LifecycleTransition

    @LifecycleTransition.setter
    def LifecycleTransition(self, LifecycleTransition):

        self._LifecycleTransition = LifecycleTransition

    @property
    def AutoScalingGroupName(self):

        return self._AutoScalingGroupName

    @AutoScalingGroupName.setter
    def AutoScalingGroupName(self, AutoScalingGroupName):

        self._AutoScalingGroupName = AutoScalingGroupName

    @property
    def EC2InstanceId(self):

        return self._EC2InstanceId

    @EC2InstanceId.setter
    def EC2InstanceId(self, EC2InstanceId):

        self._EC2InstanceId = EC2InstanceId

    @property
    def LifecycleActionToken(self):

        return self._LifecycleActionToken

    @LifecycleActionToken.setter
    def LifecycleActionToken(self, LifecycleActionToken):

        self._LifecycleActionToken = LifecycleActionToken

    @property
    def NotificationMetadata(self):

        return self._NotificationMetadata

    @NotificationMetadata.setter
    def NotificationMetadata(self, NotificationMetadata):

        self._NotificationMetadata = NotificationMetadata

    @property
    def Origin(self):

        return self._Origin

    @Origin.setter
    def Origin(self, Origin):

        self._Origin = Origin

    @property
    def Destination(self):

        return self._Destination

    @Destination.setter
    def Destination(self, Destination):

        self._Destination = Destination

    def to_dict(self):
        result = {}

        for attr, _ in six.iteritems(self._types):
            value = getattr(self, attr)
            if isinstance(value, list):
                result[attr] = list(map(
                    lambda x: x.to_dict() if hasattr(x, "to_dict") else x,
                    value
                ))
            elif hasattr(value, "to_dict"):
                result[attr] = value.to_dict()
            elif isinstance(value, dict):
                result[attr] = dict(map(
                    lambda item: (item[0], item[1].to_dict())
                    if hasattr(item[1], "to_dict") else item,
                    value.items()
                ))
            else:
                result[attr] = value
        if issubclass(EC2InstanceLaunchLifecycleAction, dict):
            for key, value in self.items():
                result[key] = value

        return result

    def to_str(self):
        return pprint.pformat(self.to_dict())

    def __repr__(self):
        return self.to_str()

    def __eq__(self, other):
        if not isinstance(other, EC2InstanceLaunchLifecycleAction):
            return False

        return self.__dict__ == other.__dict__

    def __ne__(self, other):
        return not self == other
