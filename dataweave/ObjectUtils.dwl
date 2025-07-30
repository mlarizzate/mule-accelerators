%dw 2.0
import * from dw::core::Types

fun isObject(obj) = 
  isObjectType(typeOf(obj))
  
fun isArray(obj) = 
  isArrayType(typeOf(obj))

fun toString(obj, defaultValue = null) =
  if (obj != null)
    obj.^.raw default defaultValue
  else
     defaultValue  
