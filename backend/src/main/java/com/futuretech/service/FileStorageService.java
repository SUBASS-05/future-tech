package com.futuretech.service;
import org.springframework.web.multipart.MultipartFile;
public interface FileStorageService {
    String storeFile(MultipartFile file);
    void deleteFile(String fileUrl);
}
