#!/bin/bash

#Процедуры
ExtractTreeFS(){ local folderPath="$1" 
	# Получим информацию о содержимом папки с диска И отсортируем по иерархии и алфавиту здесь, т.к. разделить эти 2 действия пока нет возможности.
	
	find -P "$folderPath" -maxdepth 0 -printf "$formatFindPrint" 

	Recursion(){ local folderPath="$1"
		find -P "$folderPath"                      -maxdepth 1 ! -type d -printf "$formatFindPrint" | sort -fs -t "$separator" -k "$positionPath"
		local infoFolders="$(find -P "$folderPath" -maxdepth 1   -type d -printf "$formatFindPrint" | tail -n +2 | sort -fs -t "$separator" -k "$positionPath" )"
		if [[ -n "$infoFolders" ]]; then
			while IFS= read -r infoFolder; do
				local path="$(echo "$infoFolder" | awk -F "$separator" -vpositionPath="$positionPath" '{ print $positionPath }')"
				echo "$infoFolder"  
				Recursion "$path"
			done < <(printf '%s\n' "$infoFolders")
		fi
	}
	Recursion "$folderPath"
}

MakeInventory(){ local crudeTree="$1" 
	local treeWithLocalParhs="$(echo "$crudeTree" | awk -vpath="$sourcefolder" -vlocalRoot='.' '{sub ( path, localRoot ); print }')"
	local treeFoldersHaveSlash="$(echo "$treeWithLocalParhs" | awk -F "$separator"  '{ if ( $1 == "d") print $0"/"; else print $0 }')"
	echo "$treeFoldersHaveSlash"
}

MakeInventoryUniversal(){ local baseReport="$1" 
	zeroFormated="$(printf '%'"$intFieldLength"'d' 0)"
	echo "$baseReport" | awk -F "$separator" -vzero="$zeroFormated" '{ if ($1 == "d") sub ($2, zero); print $0 }'
}


CalcTotals(){ local inventory="$1" 
	local cb="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="b" { i++ } END {print i}')"
	local cc="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="c" { i++ } END {print i}')"
	local cd="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="d" { i++ } END {print i}')"
	local cp="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="p" { i++ } END {print i}')"
	local cf="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="f" { i++ } END {print i}')"
	local cl="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="l" { i++ } END {print i}')"
	local cs="$(echo "$inventory" | awk -F ';' -vi=0 '$1=="s" { i++ } END {print i}')"
	local tsw="$(echo "$inventory" | awk -F ';' -vs=0 '$1!="d" {s+=$2} END {print s}')"
	local tsl="$(echo "$inventory" | awk -F ';' -vs=0         '{s+=$2} END {print s}')"
	cd=$((cd - 1)) #Корень в число вложенных папок не входит, 
	               #но для linux статистики нужно было получить его размер и сложить в общую сумму. 
	               #Но не подсчитывать в количестве.
	local tca=$((cb + cc + cp + cf + cl + cs))

	printf "cb=$cb\ncc=$cc\ncd=$cd\ncp=$cp\ncf=$cf\ncl=$cl\ncs=$cs\ntsw=$tsw\ntsl=$tsl\ntca=$tca"
}

MakeReport(){ local totals="$1" 
	eval "$totals"

	Put "count directories = $cd" \
	    "count files all types = $tca" \
	    "count file = $cf" \
	    "count block = $cb" \
	    "count character = $cc" \
	    "count pipe = $cp" \
	    "count link = $cl" \
	    "count socket = $cs" \
	    "summ sizes all = $tsl"
}

MakeReportUniversal(){ local totals="$1"
	eval "$totals"

	Put "count directories = $cd" \
	    "count files all types = $tca" \
	    "count file = $cf" \
	    "count block = $cb" \
	    "count character = $cc" \
	    "count pipe = $cp" \
	    "count link = $cl" \
	    "count socket = $cs" \
	    "summ sizes all (only files) = $tsw"
}

PreparePaths(){ path="$1"
	# удалим косые в конце пути
	echo "$path" | sed 's/\/$//'
}


set -e
set -o nounset

#Импорт библиотек
source "$(dirname "$0")/infrastructure.lib.bash"


#Глобальные константы
#  Контекстные
export LC_ALL=C
readonly intFieldLength='20'
readonly separator=';'
readonly formatFindPrint='%y'"$separator"'%'"$intFieldLength"'s'"$separator"'%p\n'
readonly positionPath='3'
#  Параметры скрипта
readonly sourcefolder="$(PreparePaths "${1:?}")" 
readonly reportfolder="$(PreparePaths "${2:?}")" 
#  Выходные файлы
readonly file_inventory="$reportfolder/inventory.txt"                     # опись целевой папки как есть
readonly file_inventoryUniversal="$reportfolder/inventoryUniversal.txt"   # опись, в которой размер папок приравнен к 0
readonly file_totalSumms="$reportfolder/totalSumms.txt"                   # итоговые суммы
readonly file_totalSummsUniversal="$reportfolder/totalSummsUniversal.txt" # итоговые суммы


#Начало скрипта
rm -rf "$reportfolder"
mkdir "$reportfolder"

tree="$(ExtractTreeFS "$sourcefolder")"
inventory="$(MakeInventory "$tree")"
echo "$inventory"                   > "$file_inventory"
MakeInventoryUniversal "$inventory" > "$file_inventoryUniversal"

totals="$(CalcTotals "$inventory")"
MakeReport          "$totals" > "$file_totalSumms"
MakeReportUniversal "$totals" > "$file_totalSummsUniversal"
