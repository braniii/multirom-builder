# Add microG Packages
echo -e 'PRODUCT_PACKAGES += \\\n    GmsCore \\\n    GsfProxy \\\n    FakeStore' >> build/target/product/base.mk

# Add F-Droid
echo -e 'PRODUCT_PACKAGES += \\\n    FDroid' >> build/target/product/base.mk
#echo -e 'PRODUCT_PACKAGES += \\\n    FDroidPrivilegedExtension \\\n    FDroid' >> build/target/product/base.mk

# Add DroidGuard Helper
echo -e 'PRODUCT_PACKAGES += \\\n    DroidGuardHelper' >> build/target/product/base.mk
