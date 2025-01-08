find $(pwd)/data/sorted -type d -name 'R01*' | awk -F/ '{print $NF","$0"/CT"}' > sample.csv
