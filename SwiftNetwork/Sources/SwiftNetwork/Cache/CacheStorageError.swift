//
//  CacheStorageError.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Errors that can occur during cache storage operations.
public enum CacheStorageError: Error {
    
    /// Unable to create the cache directory.
    case unableToCreateDirectory
    
    /// Unable to read from disk.
    case readError(Error)
    
    /// Unable to write to disk.
    case writeError(Error)
}
