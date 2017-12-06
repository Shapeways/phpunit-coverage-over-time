#!/bin/bash

START_DIR=$PWD
LOGFILE="$START_DIR/data.log"
echo "" > $LOGFILE
TEST_DIR='../portal/newTests/'
if [ ! -d "$START_DIR/$TEST_DIR" ]; then
    echo "Missing target directory. Halting."
    exit
fi
cd $TEST_DIR

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
        printError "Missing PHPUnit install at revision $REV and date $DATE. Halting."
    fi
    CODE_COVERAGE=`./vendor/phpunit/phpunit/phpunit ./tests --coverage-text | grep Summary: -A 3 -B 0`
    echo "Recording data for Revision $REV ($DATE) ..."
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

#current time
DATE=`date +"%Y-%m-%d"`
#git revision from now
ORIG_REV=`git rev-list -n 1 master`
printCoverage $DATE $ORIG_REV

for TIME_ADJUST in {1..5}
do
    #switch to next revision
    DATE=`date -v -$TIME_ADJUST"w" +"%Y-%m-%d"`
    REV=`git rev-list -n 1 --before="$DATE" master`
    SKIP_POST_CHECKOUT=1 git checkout $REV #> /dev/null 2>&1
    if [ -d "$START_DIR/$TEST_DIR" ]; then
        #record data
        printCoverage $DATE $REV
    else
        printError "Test directory not found at revision $REV and date $DATE. Halting."
    fi
done
