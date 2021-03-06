//
//  opencv.m
//  PCEv1.0.4
//
//  Created by 王浩强 on 16/3/15.
//  Copyright © 2016年 王浩强. All rights reserved.
//

#import "opencv.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>

using namespace std;
using namespace cv;

int fuck = 0;
Mat hist;
double distance(cv::Point vec1,cv::Point vec2){
    double a,b,dis;
    a = fabs(vec1.x - vec2.x);
    b = fabs(vec1.y - vec2.y);
    dis = sqrt(a*a + b*b);
    return dis;
}

static cv::Mat Pca_data(cv::InputArray raw_data){
    //    printf("Load PCA model... ");
    NSString* pcaPath = [[NSBundle mainBundle]pathForResource:@"pca" ofType:@"xml"];
    cv::FileStorage fs([pcaPath UTF8String], cv::FileStorage::READ);
    
    cv::PCA pca;
    fs["mean"] >> pca.mean ;
    fs["vectors"] >> pca.eigenvectors ;
    fs["values"] >> pca.eigenvalues ;
    fs.release();
    //    printf("done\n");
    
    cv::Mat test_data;
    pca.project(raw_data, test_data);
    
    return test_data;
}
@interface opencv()
{
    cv::CascadeClassifier faceDetector;
    cv::Ptr<cv::ml::KNearest> knn_third;
    cv::Ptr<cv::ml::KNearest> knn_mid;
    cv::Rect selection;
    
}
@end

@implementation opencv
-(id)init
{
    if(self=[super init])
    {
        if_track = 0;
    }
    return self;
}
-(void) change_selection:(CGPoint)point{
    int x,y;
    x = point.x;
    y = point.y;

    if( if_track == 0 ){
        self->selection = cv::Rect(x-10,y-10,20,20);
        //if_track = -1;
    }
}
-(UIImage*)track_object:(UIImage *)img{
    cv::Mat image;
    UIImageToMat(img, image);
    //参数
    int vmin = 10, vmax = 250, smin = 30;
    int hsize = 16;
    float hranges[] = {0,180}; //色调对应区间如何选取
    const float* phranges = hranges;
    cv::Rect trackWindow =  self->selection;;

    cv::Mat hsv, hue, mask, backproj;
    
    cvtColor(image, hsv, COLOR_BGR2HSV);
    if ( if_track != 0 ){
        int _vmin = vmin, _vmax = vmax;

        inRange(hsv, Scalar(0, smin, MIN(_vmin,_vmax)),
                Scalar(180, 256, MAX(_vmin, _vmax)), mask);//去除较弱光线的影响
        
        int ch[] = {0, 0};
        hue.create(hsv.size(), hsv.depth());
        mixChannels(&hsv, 1, &hue, 1, ch, 1);//取出明度通道，为什么不是mask通道

        //处理图片
        if(if_track < 0){
            trackWindow &= cv::Rect(0,0,image.cols,image.rows);
            Mat roi(hue, trackWindow), maskroi(mask, trackWindow);
            calcHist(&roi, 1, 0, maskroi, hist, 1, &hsize, &phranges);//计算直方图，输出到hist
            normalize(hist, hist, 0, 255, NORM_MINMAX);//进行平均化
            if_track = 1;
        }

        calcBackProject(&hue, 1, 0, hist, backproj, &phranges);
        backproj &= mask;
        RotatedRect trackBox = CamShift(backproj, trackWindow,
                            TermCriteria( TermCriteria::EPS | TermCriteria::COUNT, 10, 1 ));
        
        if( trackWindow.area() <= 1 )
        {
            int cols = backproj.cols, rows = backproj.rows, r = (MIN(cols, rows) + 5)/6;
            trackWindow = cv::Rect(trackWindow.x - r, trackWindow.y - r,
                               trackWindow.x + r, trackWindow.y + r) & cv::Rect(0, 0, cols, rows);
        }
        
        ellipse( image, trackBox, Scalar(0,0,255), 5, LINE_AA );
        //return MatToUIImage(backproj);
    }

    cv::rectangle(image, trackWindow, Scalar(0,0,255));
    return MatToUIImage(image);
}

-(void)loadfacedetc{
    NSString* cascadePath = [[NSBundle mainBundle]pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
    faceDetector.load([cascadePath UTF8String]);
}

-(void)load_file{
    NSString* cascadePath = [[NSBundle mainBundle]pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
    faceDetector.load([cascadePath UTF8String]);
    NSString* knnPath = [[NSBundle mainBundle]pathForResource:@"third_KNN" ofType:@"xml"];
    knn_third = cv::Algorithm::load<cv::ml::KNearest>([knnPath UTF8String]);
    NSString* knn_midPath = [[NSBundle mainBundle]pathForResource:@"mid_KNN" ofType:@"xml"];
    knn_mid = cv::Algorithm::load<cv::ml::KNearest>([knn_midPath UTF8String]);
    //    svm = cv::Algorithm::load<cv::ml::SVM>("third_svm.xml");
    //    logistic = cv::Algorithm::load<cv::ml::LogisticRegression>("third_logistic.xml");
    //    naive_bayes = cv::Algorithm::load<cv::ml::NormalBayesClassifier>("third_NBC.xml");
}

-(double) get_score:(UIImage*)image{
    double score;
    cv::Mat test_data;
    UIImageToMat(image, test_data);
    cv::Mat gray(test_data.rows/2, test_data.cols/2, CV_32FC1);
    cvtColor(test_data,test_data,CV_BGR2GRAY);
    cv::resize(test_data, gray, gray.size());
    std::vector<cv::Rect>faces;
    faceDetector.detectMultiScale(gray, faces, 1.1,2,0|CV_HAAR_SCALE_IMAGE,cv::Size(30,30));
    cv::Rect face;
    if(faces.size() > 1){
        printf("Get face %d", fuck++);
        
        face = faces[0];
    }
    else
        return 20.0+[self get_score_mid:image];
    
    cv::Mat getRespon(1,4,CV_32FC1);
    //   getRespon.at<float>(0) = 1.0;
    getRespon.at<float>(0) = (float)(face.width*face.height)/(gray.cols*gray.rows);
    
    double width,height;
    width = gray.rows;
    height = gray.cols;
    cv::Point pos((face.x+face.width)/2, (face.y+face.height)/2);
    vector<cv::Point> intersection;
    intersection.push_back(cv::Point(width*0.667,height*0.667));
    intersection.push_back(cv::Point(width*0.667,height*0.333));
    intersection.push_back(cv::Point(width*0.333,height*0.667));
    intersection.push_back(cv::Point(width*0.333,height*0.333));
    
    double minDis_inter = 100000;
    for(int i = 0;i<intersection.size();i++){
        //if(minDis < distance:pos :intersection[i])
        if(minDis_inter > distance(pos, intersection[i])){
            minDis_inter = distance(pos ,intersection[i]);
        }
    }
    
    double minDis_line = fabs(width*0.667 - pos.x);
    if(minDis_line > fabs(width*0.333 - pos.x)){
        minDis_line = fabs(width*0.333 - pos.x);
    }
    
    if(minDis_line > fabs(height*0.333 - pos.y)){
        minDis_line = fabs(height*0.333 - pos.y);
    }
    if(minDis_line > fabs(width*0.667 - pos.y)){
        minDis_line = fabs(width*0.667 - pos.y);
    }
    getRespon.at<float>(1) = (minDis_inter)/sqrt(width*width + height*height);
    getRespon.at<float>(2) = (minDis_line)/sqrt(width*width + height*height);
    getRespon.at<float>(3) = 0;
    
    score = knn_third->predict(getRespon);
    printf("third score: %lf\n",score);
    return score;
    
}

-(double)get_score_mid:(UIImage *)image{
    double scores;
    cv::Mat test_image,graytmp;
    UIImageToMat(image, test_image);
    graytmp.create(100, 100 , CV_32FC1);
    if(test_image.channels()!= 1){
        cvtColor(test_image, test_image, cv::COLOR_BGR2GRAY);
    }
    cv::resize(test_image, graytmp, graytmp.size());
    graytmp = graytmp.reshape(1,1);
    cv::Mat data = Pca_data(graytmp);
    scores = knn_mid->predict(data);
    
    printf("mid score: %lf\n",scores);
    return scores;
}

-(UIImage*)facedetc:(UIImage*)img{
    
    cv::Mat faceImage,tmp;
    UIImageToMat(img, faceImage);
    cv::Mat gray(faceImage.rows/2, faceImage.cols/2, CV_32FC1);
    cvtColor(faceImage,tmp,CV_BGR2GRAY);
    cv::resize(tmp, gray, gray.size());
    cv::resize(faceImage, faceImage, gray.size());
    faceImage.copyTo(gray);
    
    std::vector<cv::Rect>faces;
    faceDetector.detectMultiScale(gray, faces, 1.1,2,0|CV_HAAR_SCALE_IMAGE,cv::Size(30,30));
    for(unsigned int i= 0;i < faces.size();i++)
    {
        const cv::Rect& face = faces[i];
        cv::Point tl(face.x,face.y);
        cv::Point br = tl + cv::Point(face.width,face.height);
        
        // 四方形的画法
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        cv::rectangle(faceImage, tl, br, magenta, 4, 8, 0);
    }
    cv::resize(faceImage, faceImage, tmp.size());
    return MatToUIImage(faceImage);
}

@end
