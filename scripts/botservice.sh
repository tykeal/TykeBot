#!/bin/sh

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
  exit 1
fi

WORKDIR=<%=variables[:current_path]%>
NAME=<%=variables[:application]%>

start() {
	rvm use jruby-1.6.3@<%=variables[:application]%>

	cd ${WORKDIR}
	ruby ${NAME}.rb <%=variables[:stage]%> > log/${NAME}.log 2>&1 &
}

stop() {
	PID=`ps ax | grep [r]uby | grep ${NAME}.rb | awk '{print $1}'`
	if [ "${PID}" ]
	then
		kill ${PID}
	fi
}

restart() {
	stop
	sleep 1
	start
}

case $1 in
	start)
		start
	;;
	stop)
		stop
	;;
	restart)
		restart
	;;
esac
