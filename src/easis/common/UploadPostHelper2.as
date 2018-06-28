package easis.common {

import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import 	flash.utils.ByteArray;
import 	flash.utils.Endian;

public class UploadPostHelper2 {
	/**
	 * Boundary used to break up different parts of the http POST body
	 */
	private static var _boundary:String = "";

	/**
	 * Get the boundary for the post.
	 * Must be passed as part of the contentType of the UrlRequest
	 */
	public static function getBoundary():String {

		if(_boundary.length == 0) {
			for (var i:int = 0; i < 0x20; i++ ) {
				_boundary += String.fromCharCode( int( 97 + Math.random() * 25 ) );
			}
		}

		return _boundary;
	}
//      //要上传的图片
//      var one4data:Bitmap= model.scanvo.currentScanImage;
//      //图片转换成字符数组
//      //对传送数据编码(很重要)
//      var data:ByteArray=new JPGEncoder().encode(one4data.bitmapData);
//
//      var url:String="http://www.test.com/upload/UploadAction.action";//上传地址自己根据实际情况定
//      var request:URLRequest=new URLRequest(url);
//      //form表单提交，同时声明分隔符boundary
//      request.contentType="multipart/form-data; boundary="+UploadPostHelper.getBoundary();
//      request.requestHeaders.push(new URLRequestHeader( 'Cache-Control', 'no-cache'));
//      request.method=URLRequestMethod.POST;
//      //设置上传文件名和上传数据
//
//      //getPostData()方法主要是根据RFC1867来处理数据
//      request.data=UploadPostHelper.getPostData("test.jpg",data );
	private var _req:URLRequest;
	private var _parameters:*={};
	private var _fileMap:Array=[];
	public function  UploadPostHelper2(url:String){
		_req=new URLRequest(url);
		//form表单提交，同时声明分隔符boundary
		_req.contentType="multipart/form-data; boundary="+UploadPostHelper2.getBoundary();
		_req.requestHeaders.push(new URLRequestHeader( 'Cache-Control', 'no-cache'));
		_req.method=URLRequestMethod.POST;
	}
	/***
	 * 添加参数进去。
	 * ***/
	public function addParameter(key:String,value:String):void{
		_parameters[key]=value;
	}
	/****
	 * 添加文件内容进去。
	 * ***/
	public function addFile(fileName:String,uploadFieldName:String,fileContent:ByteArray):void{
		this._fileMap.push({
			                   fileName:fileName
			                   ,fieldName:uploadFieldName
			                   ,content:fileContent
		                   });


	}
	/***
	 * 设定request的主体部分。
	 * ***/
	private function setReqData():void{
		var i: int;
		var bytes:String;

		var postData:ByteArray = new ByteArray();
		//更改或读取数据的字节顺序
		postData.endian = Endian.BIG_ENDIAN;

		//add Filename to parameters
		if(this._parameters== null) {
			this._parameters = new Object();
		}

		//遍历parameters中的属性
		//add parameters to postData
		for(var name:String in this._parameters) {
			postData = BOUNDARY(postData);
			postData = LINEBREAK(postData);
			bytes = 'Content-Disposition: form-data; name="' + name + '"';
			for ( i = 0; i < bytes.length; i++ ) {
				postData.writeByte( bytes.charCodeAt(i) );
			}
			postData = LINEBREAK(postData);
			postData = LINEBREAK(postData);
			postData.writeUTFBytes(this._parameters[name]);
			postData = LINEBREAK(postData);
		}

		for(var j:int=0;j< this._fileMap.length;j++){
			var fileItem:*=this._fileMap[j];
			var uploadDataFieldName:*=fileItem.fieldName;
			var fileName:*=fileItem.fileName;
			var fileContent:*=fileItem.content;
			//add Filedata to postData
			postData = BOUNDARY(postData);
			postData = LINEBREAK(postData);
			bytes = 'Content-Disposition: form-data; name="'+uploadDataFieldName+'"; filename="';
			for ( i = 0; i < bytes.length; i++ ) {
				postData.writeByte( bytes.charCodeAt(i) );
			}
			postData.writeUTFBytes(fileName);
			postData = QUOTATIONMARK(postData);
			postData = LINEBREAK(postData);
			bytes = 'Content-Type: application/octet-stream';
			for ( i = 0; i < bytes.length; i++ ) {
				postData.writeByte( bytes.charCodeAt(i) );
			}
			postData = LINEBREAK(postData);
			postData = LINEBREAK(postData);
			postData.writeBytes(fileContent, 0, fileContent.length);
			postData = LINEBREAK(postData);
		}


		//closing boundary
		postData = BOUNDARY(postData);
		postData = DOUBLEDASH(postData);
		_req.data=postData;

	}

	public function getUrlRequest():URLRequest {
		this.setReqData();
		return this._req;
	}



	/**
	 * Add a boundary to the PostData with leading doubledash 添加以双破折号开始的分隔符
	 */
	private static function BOUNDARY(p:ByteArray):ByteArray {
		var l:int = UploadPostHelper2.getBoundary().length;

		p = DOUBLEDASH(p);
		for (var i:int = 0; i < l; i++ ) {
			p.writeByte( _boundary.charCodeAt( i ) );
		}
		return p;
	}

	/**
	 * Add one linebreak 添加空白行
	 */
	private static function LINEBREAK(p:ByteArray):ByteArray {
		p.writeShort(0x0d0a);
		return p;
	}

	/**
	 * Add quotation mark 添加引号
	 */
	private static function QUOTATIONMARK(p:ByteArray):ByteArray {
		p.writeByte(0x22);
		return p;
	}

	/**
	 * Add Double Dash 添加双破折号--
	 */
	private static function DOUBLEDASH(p:ByteArray):ByteArray {
		p.writeShort(0x2d2d);
		return p;
	}
}
}
