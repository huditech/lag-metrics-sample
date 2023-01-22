#!/bin/bash

az deployment group create \
    --resource-group lag-monitor-target \
    --subscription 55c079e7-8c64-4e3d-b797-a71ebda23e81 \
    -f main.bicep 
