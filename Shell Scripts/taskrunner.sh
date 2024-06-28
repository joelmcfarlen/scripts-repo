#!/bin/bash

# Flag to track if any matches are found
found_any=false

# Get the list of all pipeline IDs
pipeline_ids=$(aws datapipeline list-pipelines --query 'pipelineIdList[].id' --output text)

echo "Pipeline IDs: $pipeline_ids"

# Loop through each pipeline ID and search for the worker group
for pipeline_id in $pipeline_ids; do
  echo "Checking pipeline ID: $pipeline_id"
  
  # Get the pipeline definition
  pipeline_definition=$(aws datapipeline get-pipeline-definition --pipeline-id $pipeline_id --output json)
  
  # Print the pipeline definition for debugging
  echo "Pipeline definition for ID $pipeline_id: $pipeline_definition"
  
  # Check if the pipeline definition is valid JSON
  if echo "$pipeline_definition" | jq empty; then
    # Check if the worker group `wg-TaskRunner` is used in the pipeline definition
    worker_group_found=$(echo "$pipeline_definition" | jq -r '.pipelineObjects[]? | select(.fields[]? | select(.key == "workerGroup" and .stringValue == "wg-TaskRunner")) | .id')

    if [ -n "$worker_group_found" ]; then
      echo "Pipeline ID: $pipeline_id"
      echo "Worker Group 'wg-TaskRunner' is used in this pipeline."
      echo "----------------------------------"
      found_any=true
    fi
  else
    echo "Pipeline ID: $pipeline_id has an invalid JSON structure."
  fi
done

# Check if no matches were found
if [ "$found_any" = false ]; then
  echo "No pipelines found with the worker group 'wg-TaskRunner'."
fi
