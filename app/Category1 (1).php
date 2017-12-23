<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Category_1 extends Model
{
        protected $table = 'category1';

        public function prods1()
            {
                return $this->belongsToMany('App\Product')->withTimestamps();
            }
}
