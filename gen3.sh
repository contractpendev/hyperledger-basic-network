
rm .env
cd ./crypto-config/peerOrganizations/org1.example.com/ca/
OUTPUT="$(ls *_sk)"
echo "${OUTPUT}"
cd ../../../../
cp .env_original .env
echo "${OUTPUT}" >> .env

