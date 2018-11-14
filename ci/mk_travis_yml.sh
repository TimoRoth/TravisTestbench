#!/bin/bash
cd "$(dirname "$0")"/..

cat .travis_head.yml > .travis.yml

CONDA_BUILD_PYS="3.5 3.6 3.7"

for stage in oggm oggmdev; do
	for os in windows; do
		for CONDA_BUILD_PY in $CONDA_BUILD_PYS; do
			[[ "$stage" == "oggm" ]] && [[ "$CONDA_BUILD_PY" == "3.7" ]] && continue

			echo "    - stage: make_env" >> .travis.yml
			echo "      script: ./ci/travis_make_env_script.sh" >> .travis.yml
			echo "      env: CONDA_BUILD_PY=$CONDA_BUILD_PY SUB_STAGE=$stage" >> .travis.yml
			echo "      os: $os" >> .travis.yml
			if [[ "$os" == "osx" ]]; then
				echo "      osx_image: xcode10" >> .travis.yml
			fi
		done
	done
done

