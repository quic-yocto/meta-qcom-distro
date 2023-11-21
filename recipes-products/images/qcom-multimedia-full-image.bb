require qcom-multimedia-image.bb

SUMMARY = "Full multimedia image with gstreamer"

LICENSE = "BSD-3-Clause-Clear"

# let's make sure we have a good image.
CORE_IMAGE_EXTRA_INSTALL += " gstreamer1.0"
