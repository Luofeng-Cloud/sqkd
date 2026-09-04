import Foundation

/// 针对 iPhone 硬件定制的超级 DirectPlay 设备描述符
/// 向 Emby 服务端声明客户端具备全格式原生解码能力，阻止服务端触发高负载降质转码
public struct DirectPlayProfile {
    
    public static func makeDeviceProfile() -> [String: Any] {
        let directPlayProfiles: [[String: Any]] = [
            [
                "Container": "mkv,mp4,m4v,mov,ts,m2ts,webm,avi,wmv,flv,iso",
                "Type": "Video",
                "VideoCodec": "hevc,h265,h264,av1,vp9,vc1,mpeg4,mpeg2video",
                "AudioCodec": "aac,mp3,ac3,eac3,dts,dca,truehd,flac,opus,pcm,pcm_s16le,alac"
            ],
            [
                "Container": "flac,alac,mp3,aac,m4a,opus,wav,wma,ogg,ape",
                "Type": "Audio"
            ]
        ]
        
        let codecProfiles: [[String: Any]] = [
            [
                "Type": "Video",
                "Codec": "hevc",
                "Conditions": [
                    [
                        "Condition": "LessThanEqual",
                        "Property": "VideoBitDepth",
                        "Value": "10",
                        "IsRequired": false
                    ]
                ]
            ],
            [
                "Type": "Video",
                "Codec": "h264",
                "Conditions": [
                    [
                        "Condition": "LessThanEqual",
                        "Property": "VideoBitDepth",
                        "Value": "10",
                        "IsRequired": false
                    ]
                ]
            ]
        ]
        
        let responseProfiles: [[String: Any]] = [
            [
                "Type": "Video",
                "Container": "mkv,mp4,m4v,mov",
                "MimeType": "video/mp4"
            ]
        ]
        
        return [
            "Name": "iPhone DolbyVision Direct Engine",
            "MaxStreamingBitrate": 250_000_000, // 250 Mbps 允许超高码率 4K 原盘直出
            "MaxStaticBitrate": 250_000_000,
            "MusicStreamingTranscodingBitrate": 320000,
            "TimelineOffsetSeconds": 0,
            "DirectPlayProfiles": directPlayProfiles,
            "CodecProfiles": codecProfiles,
            "ResponseProfiles": responseProfiles,
            "SubtitleProfiles": [
                ["Format": "srt", "Method": "External"],
                ["Format": "ass", "Method": "Embed"],
                ["Format": "ssa", "Method": "Embed"],
                ["Format": "pgs", "Method": "Embed"],
                ["Format": "subrip", "Method": "External"],
                ["Format": "vtt", "Method": "External"]
            ]
        ]
    }
}
