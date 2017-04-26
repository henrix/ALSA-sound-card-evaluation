#!/bin/bash
#
# Automated test for ALSA Audio Cards
#	@param: ALSA playback device (e.g. hw:0,0)
#	@param: ALSA capture device (e.g. hw:0,0)
#   @param: soundcard name (for plots)
#	@param (optional): test function (all (default), latency, thd, crosstalk, magnitude-spectrum)
#
# Copyright (C) Henrik Langer <henni19790@googlemail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

mkdir results &> /dev/null
mkdir sine-test &> /dev/null
mkdir sine-test/thd_thdn_snr &> /dev/null
mkdir sine-test/crosstalk &> /dev/null
mkdir sine-test/magnitude-spectrum &> /dev/null

PCM_PLAYBACK=$1
PCM_CAPTURE=$2
SOUNDCARDNAME=$3
if [ "$#" == "0" ]; then
	echo "No PCM playback device (e.g. hw:0) specified. Aborting..."
	exit -1
elif [ "$#" == "1" ]; then
	echo "No PCM capture device (e.g. hw:0) specified. Aborting..."
	exit -1
elif [ "$#" == "2" ]; then
	echo "No sound card name specified. Aborting..."
	exit -1
elif [ "$#" == "3" ]; then
	echo "No test function specified. Running all tests..."
	TESTFUNC="all"
else
	TESTFUNC=$4
fi

RESULT_FILENAME="results/results-`date +%F`-$(uname -r)-$TESTFUNC.txt"
SAMPLE_RATES=("44100" "48000" "96000") # More supported sample rates can be added here
SAMPLE_FORMATS=("S16_LE" "S32_LE") # More supported sample formats can be added here
DEEMPHASIS_MODES=("None" "48kHz" "44.1kHz" "32kHz")
FREQUENCY_VECTOR_44_1=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "20" "30" "40" "50" "60" "70" "80" "90" "100" "200" "300" "400" "500" "600" "700" "800" "900" "1000" "2000" "3000" "4000" "5000" "6000" "7000" "8000" "9000" "10000" "20000" "21000")
FREQUENCY_VECTOR_48=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "20" "30" "40" "50" "60" "70" "80" "90" "100" "200" "300" "400" "500" "600" "700" "800" "900" "1000" "2000" "3000" "4000" "5000" "6000" "7000" "8000" "9000" "10000" "20000" "23000")
FREQUENCY_VECTOR_96=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "20" "30" "40" "50" "60" "70" "80" "90" "100" "200" "300" "400" "500" "600" "700" "800" "900" "1000" "2000" "3000" "4000" "5000" "6000" "7000" "8000" "9000" "10000" "20000" "30000" "40000" "47000")
FREQUENCY_VECTOR_192=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "20" "30" "40" "50" "60" "70" "80" "90" "100" "200" "300" "400" "500" "600" "700" "800" "900" "1000" "2000" "3000" "4000" "5000" "6000" "7000" "8000" "9000" "10000" "20000" "30000" "40000" "50000" "60000" "70000" "80000" "90000" "95000")

# Init sound card (have to be changed for other audio cards than CTAG face2|4)
amixer -c 0 sset ADC1 unmute &> /dev/null
amixer -c 0 sset ADC2 unmute &> /dev/null
amixer -c 0 sset 'ADC High Pass Filter' off &> /dev/null
amixer -c 0 sset 'Playback Deemphasis' 'None' &> /dev/null

echo "Begin automatic evaluation on $(uname -r) kernel..." 


#
# Latency
#
if [ "$TESTFUNC" == "all" ] || [ "$TESTFUNC" == "latency" ]; then
	echo "##### Latency #####" >> $RESULT_FILENAME
	echo "Stating ALSA latency test..."
	echo "(computer may not react for short time with realtime kernel)"

	for samplerate in "${SAMPLE_RATES[@]}"
	do
		if [ "$samplerate" == "44100" ]; then
			alsa-lib-*/test/latency --pdevice="plug:$PCM_PLAYBACK" --cdevice="plug:$PCM_PLAYBACK" --channels=2 --rate=$samplerate -m 64 -M 4096
			LATENCY_MS_NO_STRESS=$?
			echo "=>  latency (no-stress, $samplerate Hz): $LATENCY_MS_NO_STRESS ms" >> $RESULT_FILENAME
			stress --quiet --cpu 4 --io 2 --vm 2 --vm-bytes 128M --hdd 4 --hdd-bytes 64M &
			alsa-lib-*/test/latency --pdevice="plug:$PCM_PLAYBACK" --cdevice="plug:$PCM_PLAYBACK" --channels=2 --rate=$samplerate -m 64 -M 4096
			LATENCY_MS_STRESS=$?
			killall stress &> /dev/null
			echo "=>  latency (stress, $samplerate Hz): $LATENCY_MS_STRESS ms" >> $RESULT_FILENAME
			sleep 1
		else
			alsa-lib-*/test/latency --pdevice=$PCM_PLAYBACK --cdevice=$PCM_CAPTURE --channels=2 --rate=$samplerate -m 64 -M 4096
			LATENCY_MS_NO_STRESS=$?
			echo "=>  latency (no-stress, $samplerate Hz): $LATENCY_MS_NO_STRESS ms" >> $RESULT_FILENAME
			stress --quiet --cpu 4 --io 2 --vm 2 --vm-bytes 128M --hdd 4 --hdd-bytes 64M &
			alsa-lib-*/test/latency --pdevice=$PCM_PLAYBACK --cdevice=$PCM_CAPTURE --channels=2 --rate=$samplerate -m 64 -M 4096
			LATENCY_MS_STRESS=$?
			killall stress &> /dev/null
			echo "=>  latency (stress, $samplerate Hz): $LATENCY_MS_STRESS ms" >> $RESULT_FILENAME
			sleep 1
		fi
	done
fi


#
# THD, THD+N and SNR
#
if [ "$TESTFUNC" == "all" ] || [ "$TESTFUNC" == "thd" ]; then
	NUM_MEASUREMENTS=20
	echo "Starting THD, THD+N and DNR measurement..."
	echo "##### THD, THD+N and DNR with $NUM_MEASUREMENTS measurements #####" >> $RESULT_FILENAME
	
	amixer -c 0 -- sset DAC1 -1dB &> /dev/null
	amixer -c 0 sset DAC1 on &> /dev/null
	amixer -c 0 sset DAC2 off &> /dev/null
	amixer -c 0 sset DAC3 off &> /dev/null
	amixer -c 0 sset DAC4 off &> /dev/null
	sleep 1

	for samplerate in "${SAMPLE_RATES[@]}"
	do
		for sampleformat in "${SAMPLE_FORMATS[@]}"
		do
			for i in `seq 1 $NUM_MEASUREMENTS`;
        	do
                WAVPATH="sine-test/thd_thdn_snr/sine-1kHz-$samplerate-$sampleformat-$i.wav"
				if [ "$samplerate" == "44100" ]; then
					./alsa-lib*/test/pcm --device="plug:$PCM_PLAYBACK" --channels=2 --rate=$samplerate --format=$sampleformat --frequency=1000 & pid_playback=$!
					sleep 1
					arecord --device=$PCM_CAPTURE  --rate=48000 --channels=2 --format=$sampleformat --duration=1  $WAVPATH & pid_arecord=$!
				else
					./alsa-lib*/test/pcm --device=$PCM_PLAYBACK --channels=2 --rate=$samplerate --format=$sampleformat --frequency=1000 & pid_playback=$!
					sleep 1
					arecord --device=$PCM_CAPTURE --rate=$samplerate --channels=2 --format=$sampleformat --duration=1  $WAVPATH & pid_arecord=$!
				fi

				wait $pid_arecord
				kill $pid_playback
				sleep 1
        	done

        	WAVPATH_sine="sine-test/thd_thdn_snr/sine-1kHz-$samplerate-$sampleformat-"
        	if [ "$samplerate" == "44100" ]; then
        		OCTAVE_RESULT=`./octave-scripts/thd_thdn_snr.m $WAVPATH_sine 48000 $NUM_MEASUREMENTS`
        	else
        		OCTAVE_RESULT=`./octave-scripts/thd_thdn_snr.m $WAVPATH_sine $samplerate $NUM_MEASUREMENTS`
        	fi
			IFS=', ' read -r -a resarray <<< "$OCTAVE_RESULT"
			echo "$samplerate Hz, $sampleformat:" >> $RESULT_FILENAME
			#echo "=>  THD = ${resarray[0]} dB, std derivation = ${resarray[1]} dB" >> $RESULT_FILENAME
			#echo "=>  THD+N = ${resarray[2]} dB, std derivation = ${resarray[3]} dB" >> $RESULT_FILENA-m 64 ME
			#echo "=>  DNR = ${resarray[4]} dB, std derivation = ${resarray[5]} dB" >> $RESULT_FILENAME
			echo "=>  THD = ${resarray[0]} dB" >> $RESULT_FILENAME
			echo "=>  THD+N = ${resarray[1]} dB" >> $RESULT_FILENAME
			echo "=>  DNR = ${resarray[2]} dB" >> $RESULT_FILENAME
		done
	done
fi


#
# Crosstalk
#
if [ "$TESTFUNC" == "all" ] || [ "$TESTFUNC" == "crosstalk" ]; then
	echo "Starting crosstalk measurement..."
	echo "##### Crosstalk #####" >> $RESULT_FILENAME

	amixer -c 0 -- sset DAC1 0dB &> /dev/null
	amixer -c 0 sset DAC1 on &> /dev/null
	amixer -c 0 sset DAC2 off &> /dev/null
	amixer -c 0 sset DAC3 off &> /dev/null
	amixer -c 0 sset DAC4 off &> /dev/null
	amixer -c 0 sset 'Playback Deemphasis' 'None' &> /dev/null
	sleep 1

	for samplerate in "${SAMPLE_RATES[@]}"
	do
		WAVPATH="sine-test/crosstalk/sine-1kHz-$samplerate.wav"
		sleep 1
		if [ "$samplerate" == "44100" ]; then
			aplay --device="plug:$PCM_PLAYBACK"  test-data/test-1kHz-sine-1dBFS-$samplerate-left-active.wav & pid_aplay=$!
			sleep 1
			arecord --device=$PCM_CAPTURE --rate=48000 --channels=2 --format=S32_LE --duration=1  $WAVPATH & pid_arecord=$!
		else
			aplay --device=$PCM_PLAYBACK  test-data/test-1kHz-sine-1dBFS-$samplerate-left-active.wav & pid_aplay=$!
			sleep 1
			arecord --device=$PCM_CAPTURE --rate=$samplerate --channels=2 --format=S32_LE --duration=1  $WAVPATH & pid_arecord=$!
		fi
		
		wait $pid_arecord
		wait $pid_aplay
		if [ "$samplerate" == "44100" ]; then
			OCTAVE_RESULT=`./octave-scripts/crosstalk.m $WAVPATH 48000 1`
		else
			OCTAVE_RESULT=`./octave-scripts/crosstalk.m $WAVPATH $samplerate 1`
		fi
		mv crosstalk.pdf results/crosstalk-$samplerate-Hz.pdf
		mv crosstalk.png results/crosstalk-$samplerate-Hz.png
		mv crosstalk.fig results/crosstalk-$samplerate-Hz.fig
		IFS=', ' read -r -a resarray <<< "$OCTAVE_RESULT"
		echo "=>  crosstalk ($samplerate Hz): ${resarray[0]} dB" >> $RESULT_FILENAME
	done
fi


#
# Magnitude spectrum
#
if [ "$TESTFUNC" == "all" ] || [ "$TESTFUNC" == "magnitude-spectrum" ]; then

	amixer -c 0 -- sset DAC1 0dB &> /dev/null
	amixer -c 0 -- sset DAC2 0dB &> /dev/null
	amixer -c 0 -- sset DAC3 0dB &> /dev/null
	amixer -c 0 -- sset DAC4 0dB &> /dev/null
	amixer -c 0 sset DAC1 on &> /dev/null
	amixer -c 0 sset DAC2 off &> /dev/null
	amixer -c 0 sset DAC3 off &> /dev/null
	amixer -c 0 sset DAC4 off &> /dev/null
	sleep 1
	
	for samplerate in "${SAMPLE_RATES[@]}"
	do	
		echo "Starting frequency response measurement with $samplerate Hz sample rate..."

		if [ "$samplerate" == "44100" ]; then
			FREQUENCY_VECTOR=("${FREQUENCY_VECTOR_44_1[@]}")
		elif [ "$samplerate" == "48000" ]; then
			FREQUENCY_VECTOR=("${FREQUENCY_VECTOR_48[@]}")
		elif [ "$samplerate" == "96000" ]; then
			FREQUENCY_VECTOR=("${FREQUENCY_VECTOR_96[@]}")
		elif [ "$samplerate" == "192000" ]; then
			FREQUENCY_VECTOR=("${FREQUENCY_VECTOR_192[@]}")
		else
			echo "Undefined samplerate. Aborting..."
			exit -1
		fi

		for frequency in "${FREQUENCY_VECTOR[@]}"
		do
			WAVPATH="sine-test/magnitude-spectrum/sine-0dBFS-$samplerate-$frequency-Hz.wav"
			sleep 1

			if [ "$samplerate" == "44100" ]; then
				./alsa-lib*/test/pcm --device="plug:$PCM_PLAYBACK" --channels=2 --rate=$samplerate --format=S16_LE --frequency=$frequency & pid_playback=$!
				sleep 1
				arecord --device=$PCM_CAPTURE --rate=48000 --channels=2 --format=S16_LE --duration=1  $WAVPATH & pid_arecord=$!
			else
				./alsa-lib*/test/pcm --device=$PCM_PLAYBACK --channels=2 --rate=$samplerate --format=S16_LE --frequency=$frequency & pid_playback=$!
				sleep 1
				arecord --device=$PCM_CAPTURE --rate=$samplerate --channels=2 --format=S16_LE --duration=1  $WAVPATH & pid_arecord=$!
			fi
			wait $pid_arecord
			kill $pid_playback
		done
		echo "Start plotting magnitude spectrum. This can take a while..."
		if [ "$samplerate" == "44100" ]; then
			octave-scripts/magnitude_spectrum.m 48000 "$SOUNDCARDNAME"
		else
			octave-scripts/magnitude_spectrum.m $samplerate "$SOUNDCARDNAME"
		fi
		mv frequency_response.pdf results/frequency_response_$samplerate.pdf
		mv frequency_response.png results/frequency_response_$samplerate.png
		mv frequency_response.fig results/frequency_response_$samplerate.fig
	done
fi

echo "Test finished."
echo "Results were saved in $RESULT_FILENAME"
exit
