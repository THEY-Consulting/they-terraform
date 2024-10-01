#!/bin/bash

echo "$(aws sns list-topics --query "Topics[?ends_with(TopicArn, 'they-test-sns.fifo')].TopicArn" --output text)"

