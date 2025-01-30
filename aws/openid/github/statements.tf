locals {
  tfstate_statements = [
    {
      Effect : "Allow",
      Action : [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:DeleteObject",
      ],
      Resource : [
        "arn:aws:s3:::${var.name}-tfstate",
        "arn:aws:s3:::${var.name}-tfstate/**"
      ]
    },
    {
      Effect : "Allow",
      Action : [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
      ],
      Resource : [
        "arn:aws:dynamodb:${local.stateLockTableRegion}:${data.aws_caller_identity.current.account_id}:table/${var.name}-tfstate-lock",
      ],
    },
  ]

  cloudfront_statements = [
    # AllowDescribeCloudfront
    {
      Effect : "Allow",
      Action : [
        "cloudfront:ListCachePolicies",
        "cloudfront:GetCachePolicy",
        "cloudfront:CreateDistribution",
        "cloudfront:ListDistributions",
      ],
      Resource : [
        "*", # must be a wildcard, see https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazoncloudfront.html
      ],
    },

    # CreateDistribution
    {
      Effect : "Allow",
      Action : [
        "cloudfront:TagResource",
      ],
      Resource : [
        "*", # unfortunately, we can't limit this to the distribution we create
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # ModifyDistribution
    {
      Effect : "Allow",
      Action : [
        "cloudfront:ListTagsForResource",
        "cloudfront:GetDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:ListConflictingAliases",
        "cloudfront:AssociateAlias",
        "cloudfront:ListFunctions",
        "cloudfront:DescribeFunction",
        "cloudfront:GetFunction",
        "cloudfront:CreateFunction",
        "cloudfront:UpdateFunction",
        "cloudfront:PublishFunction",
        "cloudfront:CreateInvalidation",
        "cloudfront:DeleteFunction",
      ],
      Resource : [
        "*", # unfortunately, we can't limit this to the distribution we create // TODO: or can we?
      ],
    },

    # AllowS3Deployment
    {
      Effect : "Allow",
      Action : [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject",
      ],
      Resource : var.cloudfront_source_bucket_arns,
    },
  ]

  cloudwatch_statements = [
    # CloutwatchLogs
    {
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "logs:DeleteLogGroup",
        "logs:CreateLogStream",
        "logs:TagResource",
        "logs:ListTagsForResource",
        "logs:PutRetentionPolicy",
        "logs:DescribeLogStreams",
        "logs:DeleteLogStream",
      ],
      Resource = "*", // TODO: limit this somehow
    },

    # CloudwatchDashboard
    {
      Effect = "Allow",
      Action = [
        "cloudwatch:GetDashboard",
        "cloudwatch:PutDashboard",
        "cloudwatch:DeleteDashboards",
      ],
      Resource = "*", // TODO: limit this somehow
    }
  ]

  ec2_statements = [
    # AllowDescribeEc2
    {
      Effect : "Allow",
      Action : [
        "ec2:DescribeImages",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcAttribute", # this could be limited to the VPCs we use but we would have to set the VPC ID here, which is not available at this point
        "ec2:DescribeInternetGateways",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSecurityGroupRules",
        "ec2:DescribeRouteTables",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeNatGateways",
        "ec2:DescribeAddresses",
        "ec2:DescribeAddressesAttribute",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribePrefixLists",
      ],
      Resource : [
        "*" # must be a wildcard, see https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html
      ]
    },

    # AllowCreateVpc
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateVpc",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*",
      ]
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToVpc
    {
      Effect : "Allow",
      Action : [
        "ec2:DeleteVpc",
        "ec2:CreateTags",
        "ec2:CreateSubnet",
        "ec2:CreateSecurityGroup",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateRouteTable",
        "ec2:CreateVpcEndpoint",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*",
      ]
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateSubnet
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateSubnet",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToSubnet
    {
      Effect : "Allow",
      Action : [
        "ec2:ModifySubnetAttribute",
        "ec2:DeleteSubnet",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateNatGateway",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*"
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateSecurityGroup
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateSecurityGroup",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToSecurityGroup
    {
      Effect : "Allow",
      Action : [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DeleteSecurityGroup",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateSecurityGroupRule
    {
      Effect : "Allow",
      Action : [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group-rule/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToSecurityGroupRule
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group-rule/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateInternetGateway
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateInternetGateway",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
      ]
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToInternetGateway
    {
      Effect : "Allow",
      Action : [
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
      ]
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateRouteTable
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateRouteTable",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:route-table/*",
      ]
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToRouteTable
    {
      Effect : "Allow",
      Action : [
        "ec2:DeleteRouteTable",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateVpcEndpoint",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:route-table/*",
      ]
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowReplaceMainRouteTableAssociation
    {
      Effect : "Allow",
      Action : [
        "ec2:ReplaceRouteTableAssociation",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:route-table/*", # TODO: Can we limit this to the default route table somehow?
      ]
    },

    # AllowCreateRoute
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateRoute",
      ],
      Resource : [
        "*", // TODO: Can we limit this somehow?
      ]
    },

    # AllowCreateNatGateway
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateNatGateway",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:natgateway/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToNatGateway
    {
      Effect : "Allow",
      Action : [
        "ec2:DeleteNatGateway",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:natgateway/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateElasticIp
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:AllocateAddress",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToElasticIp
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateNatGateway",
        "ec2:ReleaseAddress",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowDisassociateAddress
    {
      Effect : "Allow",
      Action : [
        "ec2:DisassociateAddress",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*/*",
      ],
    },

    # AllowCreateVpcEndpoint
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateVpcEndpoint"
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
      ]
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToVpcEndpoint
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:DeleteVpcEndpoints",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
      ]
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },
  ]

  elb_statements = [
    # AllowDescribeElb
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeListenerAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
      ],
      Resource : [
        "*", # must be a wildcard, see https://docs.aws.amazon.com/service-authorization/latest/reference/list_awselasticloadbalancingv2.html
      ]
    },

    # AllowTagging
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:addTags",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.name}-*/*",
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/${var.name}-*/*",
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:listener/app/${var.name}-*/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowCreateLoadBalancer
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:CreateLoadBalancer",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.name}-*/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToLoadBalancer
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:CreateListener",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.name}-*/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateLoadBalancerListener
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:CreateListener",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:listener/app/${var.name}-*/*"
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToLoadBalancerListener
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:DeleteListener",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:listener/app/${var.name}-*/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateTargetGroup
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:CreateTargetGroup",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/${var.name}-*/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToTargetGroup
    {
      Effect : "Allow",
      Action : [
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:DeleteTargetGroup",
      ],
      Resource : [
        "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/${var.name}-*/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },
  ]

  asg_statements = [
    # AllowDescribeAsg
    {
      Effect : "Allow",
      Action : [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeLoadBalancerTargetGroups",
        "ec2:DescribeVolumes",
      ],
      Resource : [
        "*", # must be a wildcard, see https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2autoscaling.html
      ]
    },

    # AllowCreateAsg
    {
      Effect : "Allow",
      Action : [
        "autoscaling:CreateAutoScalingGroup",
      ],
      Resource : [
        "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*"
      ]
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToAsg
    {
      Effect : "Allow",
      Action : [
        "autoscaling:CreateOrUpdateTags",
        "autoscaling:SetInstanceProtection",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:AttachLoadBalancerTargetGroups",
        "autoscaling:StartInstanceRefresh",
        "autoscaling:PutLifecycleHook",
        "autoscaling:DetachLoadBalancerTargetGroups",
      ],
      Resource : [
        "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*"
      ]
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateVolume
    {
      "Effect" : "Allow",
      "Action" : [
        "ec2:CreateTags",
        "ec2:CreateVolume",
      ],
      "Resource" : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*",
      ],
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToVolume
    {
      "Effect" : "Allow",
      "Action" : [
        "ec2:DeleteVolume",
        "ec2:CreateTags",
      ],
      "Resource" : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*",
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowCreateLaunchTemplate
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateTags",
        "ec2:CreateLaunchTemplate",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:launch-template/*",
      ]
      Condition : {
        StringEquals : {
          "aws:RequestTag/App" : var.name
        }
      }
    },

    # AllowRelatedToLaunchTemplate
    {
      Effect : "Allow",
      Action : [
        "ec2:CreateLaunchTemplateVersion",
        "ec2:DeleteLaunchTemplate",
        "ec2:RunInstances",
        "ec2:CreateTags",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:launch-template/*",
      ]
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowRelatedToAmi
    {
      "Effect" : "Allow",
      "Action" : [
        "ec2:RunInstances",
      ]
      "Resource" : [
        "arn:aws:ec2:${data.aws_region.current.name}::image/ami-*",
      ],
      "Condition" : {
        "StringEquals" : var.ami_condition
      }
    },

    # AllowRelatedToTagged
    {
      Effect : "Allow",
      Action : [
        "ec2:RunInstances",
      ],
      Resource : [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*",
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*",
      ],
      Condition : {
        "StringEquals" : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },

    # AllowRelatedToUnbound
    {
      "Effect" : "Allow",
      "Action" : [
        "ec2:RunInstances",
      ],
      "Resource" : [
        # TODO: do we need to limit this further? Can we?
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*", # This should be fine as we don't allow AttachVolume permissions
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key-pair/${var.instance_key_pair_name}",
      ]
    },

    # AllowTagging
    {
      "Effect" : "Allow",
      "Action" : [
        "elasticloadbalancing:AddTags",
      ],
      "Resource" : [
        "*", # Tag condition can't be used together with resource types, see https://docs.aws.amazon.com/service-authorization/latest/reference/list_awselasticloadbalancingv2.html
      ],
      Condition : {
        StringEquals : {
          "aws:ResourceTag/App" : var.name
        }
      }
    },
  ]

  route53_statements = [
    # AllowDescribeRoute53
    {
      Effect : "Allow",
      Action : [
        "route53:ListHostedZones",
        "acm:ListCertificates",
      ],
      Resource : [
        "*", # must be a wildcard, see https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonroute53.html
      ],
    },

    # AllowDescribeZone
    {
      Effect : "Allow",
      Action : [
        "route53:GetHostedZone",
        "route53:ListTagsForResource",
        "route53:ListResourceRecordSets",
      ],
      Resource : [
        var.host_zone_arn,
      ],
    },

    # AllowReadChangeStatus
    {
      Effect : "Allow",
      Action : [
        "route53:GetChange",
      ],
      Resource : [
        "arn:aws:route53:::change/*",
      ],
    },

    # AllowWriteRecord
    {
      Effect : "Allow",
      Action : [
        "route53:ChangeResourceRecordSets",
      ],
      Resource : [
        var.host_zone_arn,
      ],
      Condition : {
        StringLike : {
          "route53:ChangeResourceRecordSetsNormalizedRecordNames" : var.route53_records
        }
      }
    },

    # AllowDescribeCertificates
    {
      Effect : "Allow",
      Action : [
        "acm:DescribeCertificate",
        "acm:ListTagsForCertificate",
        "acm:GetCertificate",
      ],
      Resource : var.certificate_arns
    }
  ]

  iam_statements = [
    # AllowDescribeIam
    {
      Effect : "Allow",
      Action : [
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfilesForRole",
      ],
      Resource : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.name}-*",
      ],
    },

    # AllowCreateRoleWithBoundary
    {
      Effect : "Allow",
      Action : [
        "iam:CreateRole",
      ],
      Resource : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-*",
      ],
      "Condition" : {
        "StringEquals" : {
          "iam:PermissionsBoundary" : var.delegated_boundary_arn
        }
      }
    },

    # AllowRelatedToRole
    {
      Effect : "Allow",
      Action : [
        "iam:TagRole",
        "iam:PutRolePolicy",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:PassRole",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
      ],
      Resource : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-*",
      ],
    },

    # AllowCreateInstanceProfile
    {
      Effect : "Allow",
      Action : [
        "iam:TagInstanceProfile",
        "iam:CreateInstanceProfile",
      ],
      Resource : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.name}-*",
      ],
    },

    # AllowRelatedToInstanceProfile
    {
      Effect : "Allow",
      Action : [
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
      ],
      Resource : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.name}-*",
      ],
    },
  ]

  dynamodb_statements = [
    # AllowDescribeDynamoDb
    {
      Effect : "Allow",
      Action : [
        "dynamodb:DescribeTable",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:ListTagsOfResource",
      ],
      Resource : [
        "*", // TODO: can we limit this?
      ],
    },

    # AllowCreateDynamoDb
    {
      Effect : "Allow",
      Action : [
        "dynamodb:CreateTable",
        "dynamodb:TagResource",
        "dynamodb:UpdateTimeToLive",
        "dynamodb:DeleteTable",
      ],
      Resource : [
        "*", // TODO: can we limit this?
      ],
    },

    # AllowAccess
    {
      Effect : "Allow",
      Action : [
        "dynamodb:ListTables",
        "dynamodb:UpdateTable",
        "dynamodb:DeleteTable",
        "dynamodb:TagResource",
      ],
      Resource : var.dynamodb ? [for table_name in var.dynamodb_table_names : "arn:aws:dynamodb::${data.aws_caller_identity.current.account_id}:table/${table_name}"] : []
    },
  ]

  ecr_statements = [
    # AllowRelatedToEcr
    {
      Effect : "Allow",
      Action : [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:ListImages",
        "ecr:DeleteRepository",
        "ecr:DeleteRepositoryPolicy",
        "ecr:SetRepositoryPolicy"
      ],
      Resource : var.ecr_repository_arns
    },

    # AllowEcrToken
    {
      Effect : "Allow",
      Action : [
        "ecr:GetAuthorizationToken"
      ],
      Resource : "*"
    }
  ]
}
