<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Product_image extends Model
{
        public function product()
            {
                return $this->hasOne(Product::class);
            }
}
