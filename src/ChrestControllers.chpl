/*
 * Copyright (C) 2018 Marcos Cleison Silva Santana
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module ChrestControllers{
   use Chrest;
   
    class ChrestController
    {
        proc Get(ref req:Request, ref res:Response){
        }
        proc Post(ref req:Request, ref res:Response){
            
        }
        proc Put(ref req:Request, ref res:Response){
            
        }
        proc Delete(ref req:Request, ref res:Response){
            
        }
        proc Head(ref req:Request, ref res:Response){
            
        }
        proc Options(ref req:Request, ref res:Response){
            
        }
        proc Trace(ref req:Request, ref res:Response){
            
        }
        proc Connect(ref req:Request, ref res:Response){
            
        }

        proc Patch(ref req:Request, ref res:Response){
            
        }

    }

    class ChrestControllerInterface{
        forwarding var controller: ChrestController;
    }

}