#!/bin/bash

# This script downloads the selected version of papermc from their server.
# Documentation about the papermc api for downloading builds is available under:
# https://docs.papermc.io/misc/downloads-service/

# Enter server directory
cd papermc

# Set nullstrings back to 'latest'
: ${MC_VERSION:='latest'}
: ${PAPER_BUILD:='latest'}
: ${USER_AGENT:='fAiL-ix/papermc (https://github.com/fAiL-ix/papermc)'}

# Lowercase these to avoid 404 errors on wget
MC_VERSION="${MC_VERSION,,}"
PAPER_BUILD="${PAPER_BUILD,,}"


# Get version information and build download URL and jar name
URL='https://fill.papermc.io/v3/projects/paper'
if [[ $MC_VERSION == latest ]]
then
  # Get the latest MC version
  MC_VERSION=$(curl -s -H "User-Agent: $USER_AGENT" $URL | \
    jq -r '.versions | to_entries[0] | .value[0]')
fi
URL="${URL}/versions/${MC_VERSION}/builds"
if [[ $PAPER_BUILD == latest ]]
then
  # Get the latest build
  # PAPER_BUILD=$(wget -qO - "$URL" | jq '.builds[-1]')
  LATEST_BUILD=$(curl -s -H "User-Agent: $USER_AGENT" $URL | \
    jq -r 'map(select(.channel == "STABLE")) | .[0] | .id')

    if [ "$LATEST_BUILD" != "null" ]; then
      echo "Latest stable build is $LATEST_BUILD"
      PAPER_BUILD=$LATEST_BUILD
    else
      echo "ERROR: No stable build for version $MINECRAFT_VERSION found"
      exit 1
    fi
fi

# Try to get a build URL for the requested version
BUILD_RESPONSE=$(curl -s -H "User-Agent: $USER_AGENT" ${URL}/${PAPER_BUILD})
PAPERMC_URL=$(echo "$BUILD_RESPONSE" | jq -r '.downloads."server:default".url')

JAR_NAME="paper-${MC_VERSION}-${PAPER_BUILD}.jar"

# Update if necessary
if [[ ! -e $JAR_NAME ]] && [ "$PAPERMC_URL" != "null" ]
then
  # Remove old server jar(s)
  rm -f *.jar
  # Download new server jar
  curl -o "$JAR_NAME" $PAPERMC_URL
fi

# Update eula.txt with current setting
echo "eula=${EULA:-false}" > eula.txt

# Add RAM options to Java options if necessary
if [[ -n $MC_RAM ]]
then
  JAVA_OPTS="-Xms${MC_RAM} -Xmx${MC_RAM} $JAVA_OPTS"
fi

# Start server
exec java -server $JAVA_OPTS -jar "$JAR_NAME" nogui
