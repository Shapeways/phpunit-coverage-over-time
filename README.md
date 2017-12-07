# Phpunit Code Coverage Script
Outputs json records in the following format:
> {"date": 'DATE', "revision": 'REVISION’, "classCoveragePercent": 0, "methodCoveragePercent": 0, "lineCoveragePercent": 0}

Does not currently record what repository is targeted in the file. I recommend including this in the logfile name.

1. Run codeCoverage.sh 
>`bash codeCoverage.sh`
1. Type in the path of the folder where you want to measure code coverage over time
1. Indicate how many weeks back you want to try to collect data
1. Type the name of the file where you want to log results
1. Watch it go

File will print an error if it checks out a revision where it can't run tests on the indicated directory. Any git related errors will also be displayed.