# Inherit from base AICP lilac configuration
$(call inherit-product, device/sony/lilac/aicp_lilac.mk)

PRODUCT_NAME := aicp_lilac_dcm
PRODUCT_DEVICE := lilac
PRODUCT_BRAND := Sony
PRODUCT_MODEL := SO-02K
PRODUCT_MANUFACTURER := Sony

PRODUCT_GMS_CLIENTID_BASE := android-sony

# FeliCa & NFC proprietary blobs for DCM variant
LOCAL_NFC_PATH := vendor/sony/lilac/proprietary/dcm_nfc
PRODUCT_COPY_FILES += \
    $(LOCAL_NFC_PATH)/firmware/cxd224x_firmware_ES1.0.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/cxd224x_firmware_ES1.0.bin \
    $(LOCAL_NFC_PATH)/firmware/cxd224x_firmware_ES1.1.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/cxd224x_firmware_ES1.1.bin \
    $(LOCAL_NFC_PATH)/bin/hw/android.hardware.nfc@1.1-service:$(TARGET_COPY_OUT_VENDOR)/bin/hw/android.hardware.nfc@1.1-service \
    $(LOCAL_NFC_PATH)/etc/init/android.hardware.nfc@1.1-service.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/android.hardware.nfc@1.1-service.rc \
    $(LOCAL_NFC_PATH)/etc/libnfc-cxd-224x02010010.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-cxd-224x02010010.conf \
    $(LOCAL_NFC_PATH)/etc/libnfc-cxd-224x02310011.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-cxd-224x02310011.conf \
    $(LOCAL_NFC_PATH)/etc/libnfc-cxd22xx.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-cxd22xx.conf \
    $(LOCAL_NFC_PATH)/etc/nfc_settings.conf:$(TARGET_COPY_OUT_VENDOR)/etc/nfc_settings.conf \
    $(LOCAL_NFC_PATH)/system/etc/init/init.lilac_dcm.nfc.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.lilac_dcm.nfc.rc \
    $(LOCAL_NFC_PATH)/system/etc/libnfc-nci.conf:$(TARGET_COPY_OUT_SYSTEM)/etc/libnfc-nci.conf \
    $(LOCAL_NFC_PATH)/product/etc/felica/common.cfg:$(TARGET_COPY_OUT_PRODUCT)/etc/felica/common.cfg \
    $(LOCAL_NFC_PATH)/product/etc/felica/mfm.cfg:$(TARGET_COPY_OUT_PRODUCT)/etc/felica/mfm.cfg \
    $(LOCAL_NFC_PATH)/product/etc/felica/mfs.cfg:$(TARGET_COPY_OUT_PRODUCT)/etc/felica/mfs.cfg

# APN configuration
PRODUCT_COPY_FILES += \
    device/sony/lilac/apns-conf.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/apns-conf.xml


