#! /bin/bash

source=./source
build=./build
dest=../labs.inquest.net/labs/static/docs
outfile=index.html.md
infile=labs_swagger.yaml

echo "Converting OpenAPI YAML to Markdown...."

# do we have changes?
# NOTE: we are bypassing this check and always assuming there are changes.
# diff $source/$infile $build/$infile > /dev/null 2>&1
# swagger_status=$?
swagger_status=1

if [ $swagger_status -ne 0 ]; then

    # if a local widdershins folder doesn't exist. glone the repo and install all dependencies locally.
    # NOTE: we assume npm/node is available.
    if [ ! -d ./widdershins ]; then
        git clone https://github.com/Mermade/widdershins.git
        cd widdershins
        npm i
        cd ..
    fi

    # convert from YAML to Slate.
    node ./widdershins/widdershins.js $source/$infile -o $source/prep.html.md

    # post processing.
    sed -E -e '/(get|post)__/s/_/\//g' -e 's/(get|post)\/\//\//g' $source/prep.html.md > $source/$outfile
    echo "Done"
else
    echo "No change to the OpenAPI YAML file. Skipping."
fi

echo "Check to see if the Docker container is running...."
docker container inspect slate > /dev/null 2>&1
slate_status=$?
if [ $slate_status -ne 0 ]; then
    echo "Starting the Docker container...."
    docker run -d --rm --name slate -p 4567:4567 -v $PWD/build:/srv/slate/build -v $PWD/source:/srv/slate/source slate
fi
echo "Done"

echo "Building Slate static docs...."
docker exec -it slate /bin/bash -c "bundle exec middleman build"
slate_status=$?
if [ $slate_status -ne 0 ]; then
    echo "Docker build failed."
    exit 1
fi
echo "Done"

if [ ! -d $dest ]; then
    echo "Creating the destination directory $dest...."
    mkdir $dest
    echo "Done"
fi

echo "Copying static files to $dest...."
cp -R $build/* $dest
rm $dest/prep.html
cp build_docs.sh $dest
echo "Done"

echo "Finished! Docs are running at http://localhost:4567 then 'docker stop slate' when satisfied"
exit 0
