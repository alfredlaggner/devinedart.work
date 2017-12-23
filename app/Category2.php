<?php

namespace App;

use App\Product;
use Illuminate\Database\Eloquent\Model;

class Category2 extends Model
    {
        protected $table = 'category2';

        public function prods2()
            {
                return $this->belongsToMany('App\Product')->withTimestamps();
            }
    }