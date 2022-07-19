export PGPASSWORD='gpp-es@lq'
userName=postgres
databaseServer=0.0.0.0
databaseName=postgres
numProc=1
portNumber=5433
wait=false
error=false
varPriority=random

if [ -n "${USER+1}" ]; then
  userName=postgres
fi

if [ -n "${PGDATABASE+1}" ]; then
  databaseName=$PGDATABASE
fi

if [ -n "${PGPORT+1}" ]; then
  portNumber=$PGPORT
fi

if [ -n "${PGHOST+1}" ]; then
  databaseServer=$PGHOST
fi


while getopts "U:p:h:d:j:v:w" opt; do
  case $opt in
    h) databaseServer=$OPTARG;;
    U) userName=$OPTARG;;
    p) portNumber=$OPTARG;;
    d) databaseName=$OPTARG;;
    j) numProc=$OPTARG;;
    v) varPriority=$OPTARG;;
    w) 
	useWait="-w"
	wait=true;;
    \?) 
	echo "$opt with $OPTARG"
	error=true;;
  esac
done

specificProc=${@:$OPTIND:1}
invalid=${@:$OPTIND+2:1}
[[ ! portNumber -gt 0 ]] && error=true
[[ ! numProc -gt 0 ]] && error=true
[[ ! -z "$invalid" ]] && error=true
if [ $error == true ]
then
  echo "Usage: ./luga_process.sh [-h host] [-p port] [-U user] [-d database] [-j Number_of_jobs] [proc_name_resume]" 
  echo "Default values: host=127.0.0.1 port=5432 user=postgres database=atlas Number_of_jobs=1 proc_name_resume=" 
  echo
  echo "Remark: database must accept login without password: interactive session would not be suitable for this batch script."
  exit
fi

useWait=$($wait && echo -w || echo "")
