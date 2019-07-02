# Docker containers for running mongodb+S2+healpix

Containers:
* `s2ccd_stages.Dockerfile`: all libraries, self contained
* `s2ccd_mongo_external.Dockerfile`: using mongodb from external official container

## Running the sel-suficient container

1) sample of 10K.
2) run 'docker run -it -p 27017:27017 -v /Users/fco/Code/des_dataRelease/s2se_cutouts:/home/des/s2des/external s2cut bash', inside the docker:
2.1) If by any chance/mistake the host directory is not created, then run `sudo mkdir -p /data/db`
2.2) Run `echo des | sudo -S mongod &`, here there is a thing to remember: as passw needs to be input, we use th `-S` to get it from the STDIN
3) run the `modif_s2seCCD_info_5.py` (no MPI) for 10K CCDs.
4) copy the database file into the external directory.
5) dump the entire DB `sudo mongodump -d AllCellIds_Sample -o db10K_dump` using the collection.
6) restore the DB `sudo mongorestore db10k_dump/` here pointing to the parent directory containing. It takes some time to load.
7) run the bulkthumb `s2se_9.py` over the recovered database subsample.

## Running the container communicating with external mongo container

1) start mongo instance `docker run --name base-mongo -d -p 27017:27017 mongo`. To change the exposed port, use `-p $HOSTPORT:$CONTAINERPORT`. The base mongo container is exposed by default on `27017` and is running dettached.
2) create {bridge|overlay} network `docker network create -d bridge test-network`
3) run a second container, connecting to the mongodb base container through a self-defined network. Run `docker run -it --network test-network --rm mongo mongo --host base-mongo test`

    docker run --name base-mongo -d -p 27017:27017 --net=test-network --hostname=MONGODB mongo
    docker run -it --net=test-network -p 8080:8080 --link=MONGODB s2des bash
    docker run -it --net=test-network  --link=MONGODB --name mycontainer ubuntu bash

## Testing  query

1) different tests. Need to corroborate the retrieved info is correct:
    - `python modif_s2se_9.py --ra 54 --dec -28 --return_list`: worked
    - `python modif_s2se_9.py --ra 54 --dec -28 --return_list --airmass 0`: doesn't apply the restriction. It fails.
    - `python modif_s2se_9.py --ra 54 --dec -28 --return_list --psffwhm 0`: doesn't apply the restriction. It fails.
    - `python modif_s2se_9.py --ra 54 --dec -28 --return_list --blacklist`: shouldn't get a message saying there are/aren't blacklisted CCDs?
    - `python modif_s2se_9.py --ra 54 --dec -28 --return_list --mdb aup`: if mongodb is not existent, should say so.
    - `python modif_s2se_9.py --csv test_radec.csv --return_list`: doesn't work, when asking for non-existent position it fails.
    - `python modif_s2se_9.py --ra 54 --dec -28 --make_fits --xsize 0.9 --ysize 1.1 --outdir outdir_test`: worked
        * EXTNAME: 'WGT', Error: WCS should contain celestial component
    - `python modif_s2se_9.py --ra 70 --dec -47 --xsize 180 --ysize 180 --make_fits`: test the region with lower resolution
2) from above, I need to first check: return list validity and make fits with different sizes/bands.
