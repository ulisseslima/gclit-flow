#!/bin/bash
format="$1"

case "$format" in
        DATE|-d|--date)
                df="%Y-%m-%d"
        ;;
        DT|DATET|DATETIME|DATE_TIME|-dt|--datetime|--date-time) 
                df="%Y-%m-%d %H:%M:%S"
        ;;
        T|TIME|-t|--time)
                df="%H:%M:%S"
        ;;
        *)
		echo $(($(date +%s%N)/1000000))
		exit 0
	;;
esac

date +"$df"
