# Add microG Packages
echo -e 'PRODUCT_PACKAGES += \\\n    GmsCore \\\n    GsfProxy \\\n    FakeStore' >> build/target/product/base.mk

# Add F-Droid
echo -e 'PRODUCT_PACKAGES += \\\n    FDroidPrivilegedExtension \\\n    FDroid' >> build/target/product/base.mk
