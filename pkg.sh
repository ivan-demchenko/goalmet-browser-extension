#!/bin/sh

rm -r output

mkdir output

cp -R dist/ output/dist/
cp -R images/ output/images/
cp manifest.json output/