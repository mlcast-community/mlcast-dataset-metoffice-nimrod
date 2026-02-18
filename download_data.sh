#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

wget -e robots=off --mirror --no-parent -r https://dap.ceda.ac.uk/badc/ukmo-nimrod/data/composite/uk-1km/ --header "Authorization: Bearer $API_KEY"
