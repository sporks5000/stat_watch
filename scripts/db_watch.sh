#! /bin/bash

export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

f_JOB=
v_PASSWORD=
v_USERNAME=
v_NAME=
v_IDENT=
v_HOST=
d_OUTPUT=
f_REPORT_OVERRIDE=
d_OUT_OVERRIDE=
e_MYSQL="/usr/bin/mysql"
b_SHOW_REMOVED=true
b_ONLY_DIFF=true
v_TIMESTAMP="$( date +%s )"

function fn_get_ident {
### Given a prefix and a string, create an ident
	local v_PREFIX="$1"
	local v_STRING="$2"
	v_JOB_IDENT="${v_PREFIX}_$( echo "$v_STRING" | md5sum | cut -d " " -f1 )"
	if [[ -n "$v_NAME" ]]; then
		v_JOB_IDENT="${v_NAME}_${v_JOB_IDENT}"
	fi
}

function fn_run_job {
	while IFS=$'\n' read -r v_LINE
	do
		v_LINE="$( echo "$v_LINE" | sed -E "s/(^\s*|\s*$)//g" )"
		if [[ -z "$v_LINE" || ${v_LINE:0:1} == "#" ]]; then
			continue
		fi
		v_DIREC="$( echo "$v_LINE" | cut -d " " -f1 )"
		if [[ -n "$v_DIREC" ]]; then
			v_VALUE="$( echo "$v_LINE" | cut -d " " -f2- )"
			v_VALUE="$( echo "$v_VALUE" | sed -E "s/^\s*//g" )"
			if [[ "$v_DIREC" == "MyUser" ]]; then
				v_USERNAME="$v_VALUE"
			elif [[ "$v_DIREC" == "MyPassword" ]]; then
				v_PASSWORD="$v_VALUE"
			elif [[ "$v_DIREC" == "MyHost" ]]; then
				v_HOST="-h $v_VALUE"
			elif [[ "$v_DIREC" == "MySQL" ]]; then
				e_MYSQL="$v_VALUE"
			elif [[ "$v_DIREC" == "Name" ]]; then
				v_NAME="$v_VALUE"
			elif [[ "$v_DIREC" == "Ident" ]]; then
				v_IDENT="$v_VALUE"
			elif [[ "$v_DIREC" == "OutputDir" && -d "$v_VALUE" ]]; then
				if [[ -z "$d_OUT_OVERRIDE" ]]; then
					d_OUTPUT="$v_VALUE"
				fi
			elif [[ "$v_DIREC" == "ShowRemoved" ]]; then
				b_SHOW_REMOVED=true
			elif [[ "$v_DIREC" == "IgnoreRemoved" ]]; then
				b_SHOW_REMOVED=false
			elif [[ "$v_DIREC" == "OnlyDifferences" ]]; then
				b_ONLY_DIFF=true
			elif [[ "$v_DIREC" == "FullResults" ]]; then
				b_ONLY_DIFF=false
			elif [[ $( echo "$v_DIREC" | egrep -c "^(ShowTables|RowCount|WP(Posts|Users)|Query)$" ) -gt 0 ]]; then
				if [[ -z "$d_OUTPUT" ]]; then
					echo "Cannot document task - no output directory"
					continue
				elif [[ -z "$v_USERNAME" || -z "$v_PASSWORD" ]]; then
					echo "No Database Credentials"
					continue
				fi
				if [[ -z "$v_IDENT" ]]; then
					v_IDENT="${v_DIREC} ${v_VALUE}"
				fi

				### Process each of the job types
				if [[ "$v_DIREC" == "ShowTables" ]]; then
					fn_get_ident "st" "${v_USERNAME}${v_PASSWORD}${v_VALUE}"
					"$e_MYSQL" $v_HOST -D "$v_VALUE" -p"$v_PASSWORD" -u "$v_USERNAME" --skip-column-names -B -e "SHOW TABLES" > "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt
				elif [[ "$v_DIREC" == "RowCount" ]]; then
					fn_get_ident "rc" "${v_USERNAME}${v_PASSWORD}${v_VALUE}"
					v_DB="$( echo "$v_VALUE" | cut -d "." -f1 )"
					v_TABLE="$( echo "$v_VALUE" | cut -d "." -f2- )"
					"$e_MYSQL" $v_HOST -D "$v_DB" -p"$v_PASSWORD" -u "$v_USERNAME" --skip-column-names -B -e "SELECT COUNT(*) FROM $v_TABLE" > "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt
				elif [[ "$v_DIREC" == "WPPosts" ]]; then
					fn_get_ident "wp" "${v_USERNAME}${v_PASSWORD}${v_VALUE}"
					v_DB="$( echo "$v_VALUE" | cut -d "." -f1 )"
					v_TABLE="$( echo "$v_VALUE" | cut -d "." -f2- )"
					"$e_MYSQL" $v_HOST -D "$v_DB" -p"$v_PASSWORD" -u "$v_USERNAME" --skip-column-names -B -e "SELECT ID, post_title, post_type, post_modified, comment_count, CHAR_LENGTH(post_content) FROM $v_TABLE WHERE (post_status='inherit' OR post_status='publish' OR post_status='private') AND post_type<>'revision' ORDER BY ID" > "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt
				elif [[ "$v_DIREC" == "WPUsers" ]]; then
					fn_get_ident "wu" "${v_USERNAME}${v_PASSWORD}${v_VALUE}"
					v_DB="$( echo "$v_VALUE" | cut -d "." -f1 )"
					v_TABLE="$( echo "$v_VALUE" | cut -d "." -f2- )"
					"$e_MYSQL" $v_HOST -D "$v_DB" -p"$v_PASSWORD" -u "$v_USERNAME" --skip-column-names -B -e "SELECT ID, user_login, user_email FROM $v_TABLE ORDER BY ID" > "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt
				elif [[ "$v_DIREC" == "Query" ]]; then
					fn_get_ident "qu" "${v_USERNAME}${v_PASSWORD}${v_VALUE}"
					"$e_MYSQL" $v_HOST -p"$v_PASSWORD" -u "$v_USERNAME" --skip-column-names -B -e "$v_VALUE" > "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt
				fi

				### Check the differences between results
				if [[ -f "$d_OUTPUT"/"$v_JOB_IDENT".txt ]]; then
					if [[ "$b_ONLY_DIFF" == true ]]; then
						diff "$d_OUTPUT"/"$v_JOB_IDENT".txt "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt | egrep "^[<>]" > "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt
					else
						b_OUTPUT=false
						if [[ -n "$( diff -q "$d_OUTPUT"/"$v_JOB_IDENT".txt "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt )" ]]; then
							b_OUTPUT=true
						fi
						if [[ "$b_OUTPUT" == true ]]; then
							echo -e "Before:\n" > "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt
							cat "$d_OUTPUT"/"$v_JOB_IDENT".txt >> "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt
							echo "\n\nAfter:\n" >> "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt
							cat "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt >> "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt
						fi
					fi

					### If there was output, keep it
					if [[ -f "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt && $( wc -l "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt | cut -d " " -f1 ) -gt 0 ]]; then
						### Figure out where the report file should be
						f_REPORT="$f_REPORT_OVERRIDE"
						if [[ -z "$f_REPORT" ]]; then
							f_REPORT="${d_OUTPUT}/report_${v_TIMESTAMP}.txt"
							if [[ -n "$v_NAME" ]]; then
								f_REPORT="${d_OUTPUT}/${v_NAME}_report_${v_TIMESTAMP}.txt"
							fi
						fi

						### Write to it
						echo "$v_IDENT" >> "$f_REPORT"
						echo >> "$f_REPORT"
						cat "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt >> "$f_REPORT"
						echo >> "$f_REPORT"
					fi
				fi

				### Remove all of the working files
				rm -f "$d_OUTPUT"/"$v_JOB_IDENT"_diff.txt
				mv -f "$d_OUTPUT"/"$v_JOB_IDENT"_2.txt "$d_OUTPUT"/"$v_JOB_IDENT".txt

				### Reset the identifier
				v_IDENT=
			fi
		fi
	done < "$f_JOB"
}

a_ARGS=( "$@" )
for (( c=0; c<=$(( ${#a_ARGS[@]} - 1 )); c++ )); do
	v_ARG="${a_ARGS[$c]}"
	if [[ "$v_ARG" == "--run" && -n "${a_ARGS[$c+1]}" && -f "${a_ARGS[$c+1]}" ]]; then
		c=$(( c + 1 ))
		f_JOB="${a_ARGS[$c]}"
	elif [[ "$v_ARG" == "--out" && -n "${a_ARGS[$c+1]}" ]]; then
		c=$(( c + 1 ))
		f_REPORT_OVERRIDE="${a_ARGS[$c]}"
	elif [[ "$v_ARG" == "--out-dir" && -d "${a_ARGS[$c+1]}" ]]; then
		c=$(( c + 1 ))
		d_OUT_OVERRIDE="${a_ARGS[$c]}"
		d_OUTPUT="${a_ARGS[$c]}"
	fi
done

if [[ -n "$f_JOB" ]]; then
	fn_run_job
else
	echo "Nothing to do"
fi



