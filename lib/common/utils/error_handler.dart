
import 'package:webinar/common/enums/error_enum.dart';

import '../components.dart';

class ErrorHandler{

  showError(ErrorEnum type,dynamic jsonResponse,{String? title,bool readMessage=false}){

    String? message;

    if(!readMessage){
      List<String> errors = [];
      
      jsonResponse['data']?['errors']?.forEach((k,v){
        errors.add(v.first);
      });

      if(errors.isNotEmpty){
        message = errors.first;
      }
    }

    message ??= jsonResponse['message']?.toString();

    if(message != null && message.isNotEmpty){
      showSnackBar(type, null, desc: message);
    }
    
  }
}