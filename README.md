Small testing program to save the 'volume' data of an audio file per frame to JSON format.

Mostly makes use of: https://docs.godotengine.org/en/stable/classes/class_audioeffectspectrumanalyzerinstance.html#class-audioeffectspectrumanalyzerinstance-method-get-magnitude-for-frequency-range

Main purpose of this program is to get the data, that I can then import to my other project, where the object's collider size is scaled by audio clip volume.

It's more optimized way (hope so) to do this, than to fetch the data every time the audio clip is played during project's runtime. And there's also the limit of having to use a separated audio bus for this, since the data is fetched from the aforementioned bus (other audio clips played at the same time would obviously affect the data and creating a new audio bus for every audio clip is definitely not the right way).

Not the best code I've written (still learning GDScript, also first time manipulating files using it), but it fulfills its purpose.
