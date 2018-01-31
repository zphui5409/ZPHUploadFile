//
//  ZPHUploadFile.m
//  ZPHDownImage
//
//  Created by zph on 31/01/2018.
//  Copyright © 2018 zph. All rights reserved.
//

#define kBoundary @"boundary"

#import "ZPHUploadFile.h"
@interface ZPHUploadFile ()

@property (nonatomic,strong)dispatch_queue_t uploadQueue;
@end
@implementation ZPHUploadFile

//上传图片
+(void)uploadRequestWithUrl:(NSString *)urlStr Data:(NSData *)fileData fileType:(ZPHFileType)fileType fileName:(NSString *)fileName success:(void(^)(NSData *successData))successBlock error:(void(^)(NSError *error))errorBlock {
    
    return [[self alloc]implementationUploadRequestWithUrl:urlStr Data:fileData fileType:fileType fileName:fileName success:successBlock error:errorBlock];
}

-(void)implementationUploadRequestWithUrl:(NSString *)urlStr Data:(NSData *)fileData fileType:(ZPHFileType)fileType fileName:(NSString *)fileName success:(void(^)(NSData *successData))successBlock error:(void(^)(NSError *error))errorBlock {
    
    if (!_uploadQueue) {
        _uploadQueue = dispatch_queue_create("uploadQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(_uploadQueue, ^{
        
        //大小
        NSLog(@"upload image size: %ld k",(long)(fileData.length/1024));
        
        //创建url
        NSURL *url = [NSURL URLWithString:urlStr];
        
        // 2.创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        // 文件上传使用post
        request.HTTPMethod = @"POST";
        
        //设置边界信息(bundary:服务器用来区分不同参数的唯一标示符,这个可以随便写.这样的话,就相当于对服务器声明了,我是要传输很多数据的,通过kvc的方式来设置,key是固定的,value基本也是固定格式,只不过boundary不同,要设置为POST请求)
        NSString *type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary];
        [request setValue:type forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json,text/javascript,*/*;q=0.01" forHTTPHeaderField:@"ACCEPT"];
        [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
        
        //3.创建请求体
        //拼接第一个
        NSMutableData *data = [[NSMutableData alloc]init];
        //上边界
        NSMutableString *headerStr = [NSMutableString stringWithFormat:@"--%@\r\n",kBoundary];
        //提交的表单内容(描述部分)
        //name:服务器接收文件参数的 key 值
        [headerStr appendFormat:@"Content-Disposition: form-data; name=\"header\"; filename=\"%@\"\r\n",fileName];
        //提交数据的格式(参数的类型,图片音频这些)
        switch (fileType) {
            case ZPHFileTypeImage:[headerStr appendFormat:@"Content-Type: %@\r\n\r\n",@"image/jpg/png/file"];
                break;
            case ZPHFileTypeVoice:[headerStr appendFormat:@"Content-Type: %@\r\n\r\n",@"audio/mpeg3"];
                break;
        }
        
        //将上边界添加到请求体
        [data appendData:[headerStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        //添加文件(图片/音频)数据
        [data appendData:fileData];
        
        //下边界
        NSMutableString *footerStr = [NSMutableString stringWithFormat:@"\r\n--%@--",kBoundary];
        //将下边界添加到请求体
        [data appendData:[footerStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        //添加请求体
        request.HTTPBody= data;
        
        //4.发送请求
        //网络会话
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:nil completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error) {
                if (errorBlock) {
                    errorBlock(error);
                }
                return;
            }
            
            if (data) {
//                NSLog(@"data - %@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                if (successBlock) {
                    successBlock(data);
                }
            }
        }];
        
        //开启网络任务
        [task resume];
    });
}
@end
