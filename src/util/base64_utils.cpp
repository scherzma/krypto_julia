// src/util/base64_utils.cpp
#include "base64_utils.h"
#include <openssl/bio.h>
#include <openssl/evp.h>
#include <stdexcept>
#include <openssl/buffer.h>

std::string base64_encode(const std::vector<uint8_t>& data) {
    BIO *bio, *b64;
    BUF_MEM *buffer_ptr;
    
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_new(BIO_s_mem());
    bio = BIO_push(b64, bio);
    
    // Do not use newlines to flush buffer
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    
    BIO_write(bio, data.data(), data.size());
    if (BIO_flush(bio) != 1) {
        BIO_free_all(bio);
        throw std::runtime_error("BIO_flush failed");
    }
    BIO_get_mem_ptr(bio, &buffer_ptr);
    
    std::string base64_str(buffer_ptr->data, buffer_ptr->length);
    BIO_free_all(bio);
    
    return base64_str;
}

std::vector<uint8_t> base64_decode(const std::string& base64_str) {
    BIO *bio, *b64;
    int decodeLen = (base64_str.length() * 3) / 4;
    std::vector<uint8_t> buffer(decodeLen);
    
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_new_mem_buf(base64_str.data(), base64_str.length());
    bio = BIO_push(b64, bio);
    
    // Do not use newlines to flush buffer
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    
    int length = BIO_read(bio, buffer.data(), buffer.size());
    if(length < 0){
        BIO_free_all(bio);
        throw std::runtime_error("BIO_read failed");
    }
    buffer.resize(length);
    BIO_free_all(bio);
    
    return buffer;
}
