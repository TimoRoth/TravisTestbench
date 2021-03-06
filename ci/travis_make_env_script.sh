#!/bin/bash

set -xe
cd "$(dirname "$0")/.."

export MPLBACKEND=agg

source ./ci/install_miniconda.sh

conda config --set always_yes yes --set changeps1 no

conda create -n oggm_env -c oggm -c conda-forge "python=$CONDA_BUILD_PY"
source activate oggm_env

conda install -c oggm -c conda-forge "$SUB_STAGE" pytest pytest-mpl

if [[ "$SUB_STAGE" == "oggm" ]]; then
	pytest --mpl-oggm -k "not test_googlemap" --pyargs oggm
else
	pytest --mpl-oggm --run-download --pyargs oggm
fi

ENV_FILE_NAME="${SUB_STAGE}-$(conda list -f -e "$SUB_STAGE" | tail -n1 | cut -d= -f2)_$(date +%Y%m%d)_py${CONDA_BUILD_PY/./}.yml"

conda env export -f "$ENV_FILE_NAME"

git config --global user.email "travis@travis-ci.com"
git config --global user.name "Travis CI"

set +x
git clone -q "https://${GH_TOKEN}@github.com/OGGM/OGGM-dependency-list" "/tmp/deplist_repo"

DDIR="/tmp/deplist_repo/$TRAVIS_OS_NAME"
mkdir -p "$DDIR"
test -f "$DDIR/$ENV_FILE_NAME" && MODEV="Update" || MODEV="Add"
mv "$ENV_FILE_NAME" "$DDIR"
cd "$DDIR"
git add "$ENV_FILE_NAME"

git commit -m "$MODEV $TRAVIS_OS_NAME/$ENV_FILE_NAME" || exit 0

exit 0

CNT=0
while ! git push -q; do
	CNT=$(( $CNT + 1 ))
	if [[ $CNT -gt 5 ]]; then
		echo "Max push retries exceeded"
		exit 1
	fi
	sleep 5
	echo "Push failed, trying pull --rebase"
	git pull -q --rebase
done
