#! /bin/bash

source=./source
build=./build
dest=../labs.inquest.net/labs/static/docs
outfile=index.html.md
infile=labs_swagger.yaml

echo "Converting OpenAPI YAML to Markdown...."
diff $source/$infile $build/$infile > /dev/null 2>&1
swagger_status=$?
if [ $swagger_status -ne 0 ]; then
    widdershins $source/$infile -o $source/prep.html.md
    sed -E -e '/(get|post)__/s/_/\//g' -e 's/(get|post)\/\//\//g' $source/prep.html.md > $source/$outfile
    # sed -E -e 's/(get|post)__/\1 /' -e '/(## |id\=\")(get|post) /s/_/\//g' $source/prep.html.md > $source/$outfile
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

echo "Finished! Docs are running at http://localhost:4567"
exit 0
