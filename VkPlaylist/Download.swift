//
//  Download.swift
//  VkPlaylist
//
//  MIT License
//
//  Copyright (c) 2016 Ilya Khalyapin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import SwiftyVK

/// Загрузка аудиозаписи
class Download: NSObject {
    
    /// Загружаемая аудиозапись
    var track: Track
    /// Ссылка по которой производится загрузка
    var url: NSURL
    
    /// Скачивается ли сейчас
    var isDownloading = false
    /// Находится ли в очереди на загрузку
    var inQueue = false
    
    /// Всего байт записано
    var totalBytesWritten: Int64 = 0
    /// Всего байт надо записать
    var totalBytesExpectedToWrite: Int64?
    /// Прогресс выполнения загрузки
    var progress: Float {
        guard let totalBytesExpectedToWrite = totalBytesExpectedToWrite else {
            return 0
        }
        
        return Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    }
    /// Размер загружаемого файла
    var totalSize: String? {
        guard let totalBytesExpectedToWrite = totalBytesExpectedToWrite else {
            return nil
        }
        
        return NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: .Binary)
    }
    
    /// Задание на загрузку
    var downloadTask: NSURLSessionDownloadTask?
    /// Данные для продолжения загрузки после паузы
    var resumeData: NSData?
    
    
    init?(track: Track) {
        self.track = track
        
        if let URLObject = NSURL(string: track.url) {
            self.url = URLObject
        } else {
            return nil
        }
    }
    
    
    /// Слова аудиозаписи
    var lyrics = ""
    /// Запрос на получение слов аудиозаписи
    var lyricsRequest: Request?
    /// Получаются ли слова аудиозаписи в данный момент
    var isLyricsDownloads = false
    
    
    /// Отправить запрос на получение слов аудиозаписи
    func getLyrics() {
        if let lyrics_id = track.lyrics_id {
            isLyricsDownloads = true
            
            VKAPIManager.sharedInstance.addLyricsDelegate(self)
            lyricsRequest = VKAPIManager.audioGetLyrics(lyrics_id)
        }
    }
    
    /// Отменить запрос на получение слов аудиозаписи
    func cancelGetLyrics() {
        isLyricsDownloads = false
        
        lyricsRequest?.cancel()
        lyricsRequest = nil
        VKAPIManager.sharedInstance.deleteLyricsDelegate(self)
    }
    
}


// MARK: VKAPIManagerLyricsDelegate

extension Download: VKAPIManagerLyricsDelegate {
    
    // VKAPIManager получил слова с указанным id
    func VKAPIManagerLyricsDelegateGetLyrics(lyrics: String, forLyricsID lyricsID: Int) {
        if lyricsID == track.lyrics_id! {
            isLyricsDownloads = false
            
            lyricsRequest = nil
            VKAPIManager.sharedInstance.deleteLyricsDelegate(self)
            
            self.lyrics = lyrics
        }
    }
    
    // VKAPIManager получил ошибку при получении слов с указанным id
    func VKAPIManagerLyricsDelegateErrorLyricsWithID(lyricsID: Int) {
        if lyricsID == track.lyrics_id! {
            isLyricsDownloads = false
            
            lyricsRequest = nil
            VKAPIManager.sharedInstance.deleteLyricsDelegate(self)
            
            lyrics = ""
        }
    }
    
}