#!/bin/bash

# Script pour générer un chapitrage MKV au format OGM.
# https://www.bunkus.org/videotools/mkvtoolnix/doc/mkvmerge-gui.html#chaptereditor
# Retours :
# 0 OK
# 1 Type de fichier non géré


##
# Création du numéro de chapitre avec un nombre de 0 adapté au nombre de
# chapitres.
# Ex : on affiche 024 s'il y a plus de 100 chapitres mais on affiche 1 s'il y
# en a moins de 10.
# Ex d'appel : chapter_num nb_chapters num_chapter
#              chapter_num 2 4 retourne "04"
chapter_num()
{
    chapter_num_length=$(echo $1 | wc -c)
    chapter_num_length=$(($chapter_num_length-1)) # On ne compte pas le \n
    printf %0.${chapter_num_length}d $2
}


##
# Ecriture du chapitre (position ou nom)
# Ex d'appel :
#   chapter_display -t 02 00:32:28.001
#   chapter_display -n 04 "Le titre"
chapter_display()
{
    case $1 in
        -t)
            echo "CHAPTER${2}=$3"
            ;;
        -n)
            echo "CHAPTER${2}NAME=$3"
            ;;
    esac
}


##
# Somme de deux durées exprimées en HH:MM:SS.MMM
# Ex d'appel :
#   chapter_time_add time1 time2
#   chapter_time_add 00:45:00.105 00:10:01.100
chapter_time_add()
{
    # Séparation des millisecondes et de la durée proprement dite
    IFS=. read time1 ms1 <<< "$1"
    IFS=. read time2 ms2 <<< "$2"

    # Conversion en secondes
    second1=$(echo $time1 | sed 's/:/*60+/g;s/*60/&&/'| bc)
    second2=$(echo $time2 | sed 's/:/*60+/g;s/*60/&&/'| bc)

    # Somme des durées
    ms=$(($ms1+$ms2))
    ss=$(($second1+$second2))
    mm=0
    hh=0

    # Formattage

    while [ $ms -gt 999 ]
    do
        ms=$(($ms-1000))
        ss=$(($ss+1))
    done

    while [ $ss -gt 59 ]
    do
        ss=$(($ss-60))
        mm=$(($mm+1))
    done

    while [ $mm -gt 59 ]
    do
        mm=$(($mm-60))
        hh=$(($hh+1))
    done

    printf %02d:%02d:%02d.%03d $hh $mm $ss $ms
}


##
# Retourne la durée de ce qui va devenir un chapitre
# Ex d'appel : chapter_length mkv mon_fichier.mkv
chapter_length()
{
    # TODO Gérer les fichiers avi

    case $1 in
        mkv)
            # La ligne de mkvinfo ressemble à
            # | + Durée : 26238.496s (07:17:18.496)
            # TODO y'a pas une commande qui me donnerait la durée de façon plus
            # fiable ?
            length=$(mkvinfo $2 | grep "Durée :" | sed 's/.*s (\(.*\))$/\1/')
            ;;
        *)
            exit 1 # TODO ça marche pas bien ça
    esac

    echo $length
}


chapter_num=1
chrono="00:00:00.000"

IFS=$'\n' && for param in $@;
do
    # On formatte correctement le numéro du chapitre
    chapter_num_f=$(chapter_num $# $chapter_num)

    # On affiche le temps du chapitre.
    chapter_display -t $chapter_num_f $chrono

    # On affiche le titre du chapitre (à défaut de mieux, le nom du fichier).
    filename=$(basename "$param")
    extension="${filename##*.}"
    filename="${filename%.*}"
    chapter_display -n $chapter_num_f $filename

    # On prépare le prochain chapitre
    chapter_num=$(($chapter_num+1))
    length=$(chapter_length $extension $param)
    chrono=$(chapter_time_add $chrono $length)
done


exit 0

