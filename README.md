# ALSA sound card evaluation

## Introduction
This repo contains a set of evaluation scripts based on GNU Octave.
Currently the following (automated) measurements are supported:
* Latency
* Total-Harmonic-Distortion (THD)
* Total-Harmonic-Distortion + Noise (THD+N)
* Signal to Noise Ratio (SNR)
* Crosstalk (including plots)
* Magnitude Spectrum (including plots)

The scripts were created for the evaluation of the self developed multi-channel soundcard [CTAG face2|4](https://hackaday.io/project/9634-linux-based-low-latency-multichannel-audio-system).

## Build instructions
The dependencies (e.g. GNU Octave) can be easily installed with the script install_dependencies.sh.
Sources for apt (package manager) have to be enabled in /etc/apt/sources.list.

## Execution
Input (i.e. ADC) channel 1 has to be connected to output (i.e. DAC) channel 2 (loopback).
To run a test, simply execute the start_test.sh script with the following parameters:
1. Playback device (e.g. hw:0)
2. Capture decvice (e.g. hw:0)
3. Name of audio card (is used for plots (e.g. CTAG face2|4))
4. Optional: Name of single test (latency, thd, crosstalk or magnitude-spectrum)

### Example
./start_test.sh hw:0 hw:0 CTAG thd
