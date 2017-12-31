<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Cw_product extends Model
    {
        protected $connection = 'mysql2';
        protected $primaryKey = 'product_id'; // or null

        public function products()
            {
                $this->hasOne(Product::class,'id','product_id');
            }
    }
