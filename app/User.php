<?php

namespace App;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Auth\Authenticatable as AuthenticableTrait;
use Illuminate\Database\Eloquent\Model;

class User extends Model implements Authenticatable
    {
        use AuthenticableTrait;    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
        protected $fillable = [
            'name', 'email', 'password','phone_number',
        ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
        protected $hidden = [
            'password', 'remember_token',
        ];

    }
