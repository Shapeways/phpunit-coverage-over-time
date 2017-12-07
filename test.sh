#!/bin/bash

read -p "What directory do you want to run Code Coverage on? " TEST_DIR
if [ ! -d "$TEST_DIR" ]; then
    echo "[CODE COVERAGE SCRIPT] Missing target directory. Halting."
    exit
fi

read -p "How many weeks do you want to measure Code Coverage across? " WEEK_COUNT
if [[ -n ${WEEK_COUNT//[0-9]/} ]]; then
    echo "[CODE COVERAGE SCRIPT] Input for number of weeks must be a number."
    exit
fi

read -p "What do you want to name the resulting log file? " LOGFILE_NAME
START_DIR=$PWD
LOGFILE="$START_DIR/$LOGFILE_NAME"
if [ -e $LOGFILE ]; then
    echo "[CODE COVERAGE SCRIPT] That file already exists. Do you want to overwrite it?"
    select yn in "Yes" "No"; do
        case $yn in
            #file exists, overwrite file
            Yes ) echo "" > $LOGFILE; break;;
            No ) exit;;
        esac
    done
fi

#print error message and reset test dir to head and come back to the current directory
function printError()
{
    MESSAGE=$1

    #switch back to the latest commit
    SKIP_POST_CHECKOUT=1 git checkout master #> /dev/null 2>&1
    cd $START_DIR
    echo $MESSAGE
    exit
}

#{"date": '$DATE', "revision": '$REV', "classCoveragePercent": $6, "methodCoveragePercent": $11, "lineCoveragePercent": $16},
function printCoverage () {
    DATE=$1
    REV=$2
    REV=`git rev-parse HEAD`

    #get phpunit code coverage
    if [ ! -d "./vendor/phpunit/phpunit/" ]; then
        printError "[CODE COVERAGE SCRIPT]  Missing PHPUnit install at revision $REV and date $DATE. Halting."
    fi
    CODE_COVERAGE=`./vendor/phpunit/phpunit/phpunit ./tests --coverage-text | grep Summary: -A 3 -B 0`
    echo "[CODE COVERAGE SCRIPT] Recording data for Revision $REV ($DATE) ..."
    printf "%s" "{\"date\": '$DATE', \"revision\": '$REV', " >> $LOGFILE
    echo $CODE_COVERAGE | awk '{
    classPercent = $6 ; classCount = $7 ;
    methodPercent = $11 ; methodCount = $12 ;
    linePercent = $16 ; lineCount = $17 ;
    printf "%s%.2f%s", "\"classCoveragePercent\": ",classPercent,", "
    printf "%s%.2f%s", "\"methodCoveragePercent\": ",methodPercent,", "
    printf "%s%.2f", "\"lineCoveragePercent\": ",linePercent
    print "},"
    }' >> $LOGFILE
}

# start the work
cd $TEST_DIR

#current time
DATE=`date +"%Y-%m-%d"`
#git revision from now
ORIG_REV=`git rev-list -n 1 master`
printCoverage $DATE $ORIG_REV

for TIME_ADJUST in $(seq 1 $WEEK_COUNT)
do
    #switch to next revision
    DATE=`date -v -$TIME_ADJUST"w" +"%Y-%m-%d"`
    REV=`git rev-list -n 1 --before="$DATE" master`
    SKIP_POST_CHECKOUT=1 git checkout $REV #> /dev/null 2>&1
    if [ -d "$START_DIR/$TEST_DIR" ]; then
        #record data
        printCoverage $DATE $REV
    else
        printError "[CODE COVERAGE SCRIPT] Test directory not found at revision $REV and date $DATE. Halting."
    fi
done
