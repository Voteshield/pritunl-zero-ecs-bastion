[
  {
    "name": "pritunl-zero-bastion",
    "image": "${aws_account}.dkr.ecr.us-east-1.amazonaws.com/pritunl-zero-ecs-bastion:latest",
    "cpu": ${fargate_cpu},
    "memory": ${fargate_memory},
    "networkMode": "awsvpc",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/pritunl-zero-bastion",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "secrets": [
      {
        "name": "TP_URL",
        "valueFrom": "ssm_or_kms"
      },
      {
        "name": "PTZ_ROLE",
        "valueFrom": "ssm_or_kms"
      },
      {
        "name": "BASTION_SSH_HOST_ED25519_KEY",
        "valueFrom": "ssm_or_kms"
      },
      {
        "name": "BASTION_USER",
        "valueFrom": "ssm_or_kms"
      }
    ],
    "portMappings": [
      {
        "containerPort": 22,
        "hostPort": 22
      },
      {
        "containerPort": 8000,
        "hostPort": 8000
      }
    ]
  }
]
