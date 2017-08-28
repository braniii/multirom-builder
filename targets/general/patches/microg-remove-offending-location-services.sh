#!/bin/bash
#
# Needs still som work
## Cover case:
##  PRODUCT_PACKAGES += \
## 	    com.qualcomm.location
#find vendor/ -type f -name *-vendor*.mk -print0 | xargs -0 ex -s +'/com.qualcomm.location$/-1 s/.*+=\ \\$// | x'
#
#find vendor/ -type f -name *-vendor*.mk -print0 | xargs -0 ex -s +'/com.qualcomm.location$/-1 s/.*+=\ \\$// | x'
#
## Cover case:
##           blablubldwlrg \
## 	    com.qualcomm.location
#
## Lines containing no / in the end cannot just be removed.
## We need to remove there the / in the line before
#find vendor/ -type f -name *-vendor*.mk -print0 | xargs -0 ex -s +'/com.qualcomm.location.*\ $/-1 s/\\$// | x'



# Remove all lines matching
#  com.qualcomm.location.*/
# This is safe because lines are in the middle
find vendor/ -type f -name *-vendor*.mk -print0 | xargs -0 sed -i '/com.qualcomm.location.*\\/d'



