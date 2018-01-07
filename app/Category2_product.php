<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Category2_product extends Model
    {
        protected $table = 'category2_product';
        protected $fillable = [
            'product_id',
            'category2_id',
        ];
    }
