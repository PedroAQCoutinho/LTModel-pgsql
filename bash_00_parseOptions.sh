userName=postgres
databaseServer=127.0.0.1
databaseName=atlas
numProc=1
portNumber=5432
wait=false
error=false

while getopts "U:p:h:d:j:w" opt; do
  case $opt in
    h) databaseServer=$OPTARG;;
    U) userName=$OPTARG;;
    p) portNumber=$OPTARG;;
    d) databaseName=$OPTARG;;
    j) numProc=$OPTARG;;
    w) wait=true;;
    \?) error=true;;
  esac
done

specificProc=${@:$OPTIND:1}
invalid=${@:$OPTIND+1:1}

[[ ! -z "$invalid" ]] && error=true
if [ $error == true ]
then
  echo "Usage: ./bash_04_run_all_3_models.sh [-U user] [-h host] [-p port] [-d database] [-j Number_of_jobs] proc_name_resume"
  exit
fi

useWait=$($wait && echo -w || echo "")
