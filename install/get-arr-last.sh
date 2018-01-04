#!/bin/bash
ARR=(12 33 44 55 66 77)
echo ${ARR[${#ARR[*]}-1]}
